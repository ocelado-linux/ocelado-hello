#pragma once
#include <QtCore/QCoreApplication>
#include <QtCore/QEvent>
#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtGui/QGuiApplication>
#include <QtGui/QKeyEvent>

#include <atomic>
#include <chrono>
#include <cstdint>

// Wayland app_id / window icon: must match ocelado-hello.desktop
inline void setDesktopFileName(const QString &name)
{
    QGuiApplication::setDesktopFileName(name);
}

// ---- One controller press, one action ----
//
// In the desktop session Steam applies its desktop controller layout: the
// d-pad and A/B also arrive as arrow/Enter/Esc keys, on top of what gilrs
// reads from the controller. Whichever comes first wins; the other one is
// dropped if it arrives within kPadWindowMs.

namespace ocelado_pad {
constexpr int64_t kPadWindowMs = 250;

inline int64_t nowMs()
{
    using namespace std::chrono;
    return duration_cast<milliseconds>(steady_clock::now().time_since_epoch()).count();
}

inline std::atomic<int64_t> &lastPad()
{
    static std::atomic<int64_t> v{-100000};
    return v;
}

inline std::atomic<int64_t> &lastKey()
{
    static std::atomic<int64_t> v{-100000};
    return v;
}

inline bool isNavKey(int key)
{
    switch (key) {
    case Qt::Key_Up:
    case Qt::Key_Down:
    case Qt::Key_Left:
    case Qt::Key_Right:
    case Qt::Key_Return:
    case Qt::Key_Enter:
    case Qt::Key_Escape:
        return true;
    default:
        return false;
    }
}

class KeyFilter : public QObject
{
public:
    bool eventFilter(QObject *watched, QEvent *event) override
    {
        if (event->type() == QEvent::KeyPress || event->type() == QEvent::KeyRelease) {
            auto *key = static_cast<QKeyEvent *>(event);
            if (isNavKey(key->key())) {
                const int64_t now = nowMs();
                if (now - lastPad().load() < kPadWindowMs)
                    return true; // the gamepad already did it
                if (event->type() == QEvent::KeyPress)
                    lastKey().store(now);
            }
        }
        return QObject::eventFilter(watched, event);
    }
};
} // namespace ocelado_pad

inline void installPadKeyFilter()
{
    static ocelado_pad::KeyFilter filter;
    QCoreApplication::instance()->installEventFilter(&filter);
}

inline bool gamepadEventAllowed()
{
    using namespace ocelado_pad;
    const int64_t now = nowMs();
    if (now - lastKey().load() < kPadWindowMs)
        return false; // the key already did it
    lastPad().store(now);
    return true;
}

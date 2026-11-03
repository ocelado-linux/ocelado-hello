#pragma once
#include <QtGui/QGuiApplication>
#include <QtCore/QString>

// Wayland app_id / window icon: must match ocelado-hello.desktop
inline void setDesktopFileName(const QString &name)
{
    QGuiApplication::setDesktopFileName(name);
}

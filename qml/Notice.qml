import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.ocelado.hello

// Short message at the bottom after an action finishes.
Popup {
    id: popup
    property bool ok: true
    property string message: ""

    function show(success, text) {
        ok = success
        message = text
        open()
        timer.restart()
    }

    parent: Overlay.overlay
    x: (parent.width - width) / 2
    y: parent.height - height - (Theme.handheld ? 84 : 28)
    width: Math.min(parent.width - 48, 640)
    padding: Theme.handheld ? 18 : 14
    closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
    modal: false
    focus: false

    background: Rectangle {
        radius: 12
        color: popup.ok ? Theme.accentSoft : "#3a1f24"
        border.color: popup.ok ? Theme.accent : Theme.danger
    }

    contentItem: RowLayout {
        spacing: 12
        Icon {
            path: popup.ok ? Icons.check : Icons.help
            color: popup.ok ? Theme.accentSoftText : Theme.danger
            size: Theme.iconSize
        }
        Label {
            Layout.fillWidth: true
            text: popup.message
            color: Theme.text
            font.pixelSize: Theme.fontBody
            wrapMode: Text.WordWrap
        }
    }

    Timer {
        id: timer
        interval: popup.ok ? 5000 : 9000
        onTriggered: popup.close()
    }
}

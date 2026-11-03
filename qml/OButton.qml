import QtQuick
import QtQuick.Controls
import org.ocelado.hello

// Button in the Ocelado style. kind: "primary", "secondary" or "warning".
Button {
    id: control
    property string kind: "secondary"
    property string iconPath: ""

    implicitHeight: Theme.buttonHeight
    leftPadding: Theme.handheld ? 24 : 18
    rightPadding: leftPadding
    font.pixelSize: Theme.fontBody
    font.weight: kind === "primary" ? Font.DemiBold : Font.Medium
    focusPolicy: Qt.StrongFocus

    contentItem: Row {
        spacing: 8
        Icon {
            visible: control.iconPath !== ""
            path: control.iconPath
            size: Theme.iconSize * 0.8
            color: label.color
            anchors.verticalCenter: parent.verticalCenter
        }
        Label {
            id: label
            text: control.text
            font: control.font
            anchors.verticalCenter: parent.verticalCenter
            color: !control.enabled ? Theme.textFaint
                 : control.kind === "primary" ? Theme.accentInk
                 : control.kind === "warning" ? "#1c1608" : Theme.text
        }
    }

    background: Rectangle {
        radius: Theme.handheld ? 12 : 10
        color: !control.enabled ? Theme.surfaceAlt
             : control.kind === "primary" ? (control.down ? Qt.darker(Theme.accent, 1.15) : Theme.accent)
             : control.kind === "warning" ? Theme.amber
             : (control.down || control.hovered ? Theme.surfaceHigh : "transparent")
        border.width: control.activeFocus ? Theme.focusWidth : (control.kind === "secondary" ? 1 : 0)
        border.color: control.activeFocus ? (control.kind === "secondary" ? Theme.accent : Theme.text) : Theme.borderStrong
    }
}

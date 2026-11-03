import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.ocelado.hello

// "Are you sure?" before anything that reboots or deletes data.
Popup {
    id: dialog
    property string title: ""
    property string text: ""
    property string action: "Aceptar"
    property bool danger: false
    property var callback: null

    function ask(t, body, act, isDanger, cb) {
        title = t
        text = body
        action = act
        danger = isDanger
        callback = cb
        open()
        // Start on "Cancel": the safe choice.
        cancelButton.forceActiveFocus()
    }

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(parent.width - 48, Theme.handheld ? 620 : 520)
    modal: true
    focus: true
    padding: Theme.handheld ? 32 : 26
    closePolicy: Popup.CloseOnEscape

    Overlay.modal: Rectangle { color: Qt.rgba(0.02, 0.03, 0.02, 0.6) }

    background: Rectangle {
        radius: 16
        color: Theme.window
        border.color: Theme.border
    }

    contentItem: ColumnLayout {
        spacing: 16
        Label {
            Layout.fillWidth: true
            text: dialog.title
            color: Theme.text
            font.pixelSize: Theme.handheld ? 26 : 21
            font.weight: Font.Bold
            wrapMode: Text.WordWrap
        }
        Label {
            Layout.fillWidth: true
            text: dialog.text
            color: Theme.textSoft
            font.pixelSize: Theme.fontBody
            wrapMode: Text.WordWrap
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            Layout.topMargin: 8
            spacing: 10
            OButton {
                id: cancelButton
                text: "Cancelar"
                onClicked: dialog.close()
            }
            OButton {
                kind: dialog.danger ? "warning" : "primary"
                text: dialog.action
                onClicked: {
                    var cb = dialog.callback
                    dialog.close()
                    if (cb)
                        cb()
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.ocelado.hello

// Desktop navigation: logo, sections and the "open at login" choice.
Rectangle {
    id: bar
    property var pages: []
    property string current: ""
    signal selected(string id)

    color: Theme.chrome

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Theme.border
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        anchors.topMargin: 20
        spacing: 4

        RowLayout {
            Layout.leftMargin: 8
            Layout.bottomMargin: 18
            spacing: 12
            Image {
                source: Theme.logo
                sourceSize.width: 56
                sourceSize.height: 56
            }
            ColumnLayout {
                spacing: 0
                Label {
                    text: "Ocelado"
                    color: Theme.text
                    font.pixelSize: 17
                    font.weight: Font.Bold
                }
                Label {
                    text: Backend.editionName
                    color: Theme.textFaint
                    font.pixelSize: 12
                }
            }
        }

        Repeater {
            model: bar.pages
            delegate: AbstractButton {
                id: item
                required property var modelData
                readonly property bool active: modelData.id === bar.current
                Layout.fillWidth: true
                implicitHeight: 40
                focusPolicy: Qt.StrongFocus
                onClicked: bar.selected(modelData.id)
                Keys.onReturnPressed: clicked()

                background: Rectangle {
                    radius: 8
                    color: item.active ? Theme.accent : (item.hovered ? Theme.surface : "transparent")
                    border.width: item.activeFocus ? 2 : 0
                    border.color: item.active ? Theme.text : Theme.accent
                }
                contentItem: RowLayout {
                    spacing: 12
                    Item { implicitWidth: 2 }
                    Icon {
                        path: item.modelData.icon
                        size: 18
                        color: item.active ? Theme.accentInk : Theme.textSoft
                    }
                    Label {
                        Layout.fillWidth: true
                        text: item.modelData.title
                        color: item.active ? Theme.accentInk : Theme.textSoft
                        font.pixelSize: 14
                        font.weight: item.active ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.border
        }

        Label {
            Layout.leftMargin: 8
            Layout.topMargin: 8
            text: "Abrir al iniciar sesión"
            color: Theme.textFaint
            font.pixelSize: 12
        }

        ComboBox {
            id: autostart
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            textRole: "text"
            valueRole: "value"
            model: [
                { value: "news", text: "Solo con novedades" },
                { value: "always", text: "Siempre" },
                { value: "never", text: "Nunca" }
            ]
            currentIndex: Math.max(0, indexOfValue(Backend.autostartMode))
            onActivated: Backend.setAutostart(currentValue)
            font.pixelSize: 13

            background: Rectangle {
                implicitHeight: 40
                radius: 8
                color: Theme.surface
                border.width: autostart.activeFocus ? 2 : 1
                border.color: autostart.activeFocus ? Theme.accent : Theme.borderStrong
            }
            contentItem: Label {
                leftPadding: 10
                text: autostart.displayText
                color: Theme.text
                font: autostart.font
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }
    }
}

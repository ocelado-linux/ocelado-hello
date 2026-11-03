import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.ocelado.hello

// Handheld navigation: section tabs switched with L1/R1. The tabs take no
// focus so the d-pad stays inside the page.
Rectangle {
    id: bar
    property var pages: []
    property string current: ""
    signal selected(string id)

    implicitHeight: 76
    color: Theme.ground

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: "#22302a"
    }

    component KeyCap: Rectangle {
        property alias text: capLabel.text
        implicitWidth: capLabel.implicitWidth + 18
        implicitHeight: 26
        radius: 6
        color: "#22302a"
        Label {
            id: capLabel
            anchors.centerIn: parent
            color: Theme.textSoft
            font.pixelSize: 13
            font.weight: Font.Bold
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 36
        anchors.rightMargin: 36
        spacing: 16

        Image {
            source: Theme.logo
            sourceSize.width: 52
            sourceSize.height: 52
        }
        Label {
            visible: bar.width > 1100
            text: "Ocelado"
            color: Theme.text
            font.pixelSize: 20
            font.weight: Font.Bold
            Layout.rightMargin: 12
        }

        KeyCap { text: "L1" }

        RowLayout {
            spacing: 4
            Repeater {
                model: bar.pages
                delegate: AbstractButton {
                    id: tab
                    required property var modelData
                    readonly property bool active: modelData.id === bar.current
                    focusPolicy: Qt.NoFocus
                    implicitHeight: 48
                    leftPadding: 14
                    rightPadding: 14
                    onClicked: bar.selected(modelData.id)
                    background: Rectangle {
                        radius: 10
                        color: tab.active ? Theme.accent : "transparent"
                    }
                    contentItem: Label {
                        text: tab.modelData.short
                        color: tab.active ? Theme.accentInk : Theme.textMuted
                        font.pixelSize: 16
                        font.weight: tab.active ? Font.Bold : Font.Medium
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        KeyCap { text: "R1" }
        Item { Layout.fillWidth: true }
    }
}

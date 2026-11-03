import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.ocelado.hello

// Handheld footer with the controller buttons that do something here.
Rectangle {
    id: bar
    property var hints: []
    property bool wizard: false

    implicitHeight: 60
    color: Theme.ground

    Rectangle {
        width: parent.width
        height: 1
        color: "#22302a"
    }

    component Hint: RowLayout {
        property string key
        property string label
        spacing: 10
        Rectangle {
            readonly property bool round: ["A", "B", "X", "Y"].indexOf(parent.key) >= 0
            implicitWidth: round ? 30 : keyLabel.implicitWidth + 16
            implicitHeight: 30
            radius: round ? 15 : 6
            color: parent.key === "A" ? "#3a7d2a" : parent.key === "B" ? "#a33a3a"
                 : parent.key === "X" ? "#1f5fa0" : parent.key === "Y" ? "#8a6d12" : "#33433b"
            Label {
                id: keyLabel
                anchors.centerIn: parent
                text: parent.parent.key
                color: "white"
                font.pixelSize: 14
                font.weight: Font.Bold
            }
        }
        Label {
            text: parent.label
            color: Theme.textSoft
            font.pixelSize: 16
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 36
        anchors.rightMargin: 36
        spacing: 28
        Item { Layout.fillWidth: true }
        Hint { key: "A"; label: "Seleccionar" }
        Repeater {
            model: bar.hints
            delegate: Hint {
                required property var modelData
                key: modelData.key
                label: modelData.text
            }
        }
        Hint { key: "B"; label: bar.wizard ? "Paso anterior" : "Atrás" }
        Hint { visible: !bar.wizard; key: "L1 R1"; label: "Sección" }
    }
}

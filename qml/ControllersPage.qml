import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.ocelado.hello

PageBase {
    id: page
    title: "Mandos y hardware"
    description: "Empareja mandos, comprueba que todos los botones responden y mira cómo van el ventilador y las temperaturas."

    readonly property var sensors: JSON.parse(Backend.sensorsJson)
    readonly property var buttons: ["A", "B", "X", "Y", "L1", "R1", "L2", "R2", "L3", "R3",
                                    "View", "Menu", "Guía", "Arriba", "Abajo", "Izquierda", "Derecha"]
    property var pressed: ({})
    property string last: ""

    Connections {
        target: Backend
        function onButtonEvent(name) {
            var p = Object.assign({}, page.pressed)
            p[name] = true
            page.pressed = p
            page.last = name
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: Backend.refreshSensors()
    }

    ListRow {
        Layout.fillWidth: true
        text: "Emparejar un mando Bluetooth"
        subtitle: Backend.inGameMode
                  ? "En el Modo Juego, usa Ajustes › Bluetooth de Steam."
                  : "Abre los ajustes de Bluetooth de Plasma"
        iconPath: Icons.bluetooth
        tint: Theme.blue
        chevron: !Backend.inGameMode
        enabled: !Backend.inGameMode
        onClicked: Backend.openBluetoothSettings()
    }

    SectionLabel { text: "Probar botones" }

    Card {
        Layout.fillWidth: true
        color: Theme.surfaceAlt

        Label {
            Layout.fillWidth: true
            text: page.last === "" ? "Pulsa los botones del mando: se iluminan al detectarlos."
                                   : "Último: " + page.last
            color: Theme.textMuted
            font.pixelSize: Theme.fontBody
        }

        Flow {
            Layout.fillWidth: true
            spacing: 10
            Repeater {
                model: page.buttons
                delegate: Rectangle {
                    required property string modelData
                    readonly property bool lit: page.pressed[modelData] === true
                    width: Math.max(Theme.handheld ? 72 : 64, chip.implicitWidth + 24)
                    height: Theme.handheld ? 52 : 44
                    radius: 10
                    color: lit ? Theme.accent : Theme.surfaceHigh
                    Label {
                        id: chip
                        anchors.centerIn: parent
                        text: parent.modelData
                        color: parent.lit ? Theme.accentInk : Theme.textSoft
                        font.pixelSize: Theme.fontBody
                        font.weight: Font.Bold
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label {
                Layout.fillWidth: true
                text: "Los botones traseros solo llegan aquí si Steam Input los asigna a otro botón."
                color: Theme.textFaint
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.WordWrap
            }
            OButton {
                text: "Empezar de nuevo"
                onClicked: { page.pressed = {}; page.last = "" }
            }
        }
    }

    SectionLabel { text: "Temperaturas y ventilador" }

    GridLayout {
        Layout.fillWidth: true
        columns: page.width > 760 ? 3 : 1
        columnSpacing: Theme.gap
        rowSpacing: Theme.gap
        InfoTile {
            Layout.fillWidth: true
            label: "Ventilador"
            value: page.sensors.fans && page.sensors.fans.length > 0
                   ? page.sensors.fans.map(function (r) { return r + " rpm" }).join(" · ")
                   : "No detectado"
        }
        InfoTile {
            Layout.fillWidth: true
            label: "Procesador"
            value: page.sensors.cpu_temp ? Math.round(page.sensors.cpu_temp) + " °C" : "—"
        }
        InfoTile {
            Layout.fillWidth: true
            label: "Gráfica"
            value: page.sensors.gpu_temp ? Math.round(page.sensors.gpu_temp) + " °C" : "—"
        }
    }
}

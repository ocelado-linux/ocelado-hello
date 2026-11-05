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
    readonly property int holdMs: 1500

    // ---- Button test ----
    // While it runs the page takes every button (L1/R1 do not change
    // section, B does not go back); holding B ends it, as on SteamOS.
    property bool testing: false
    property var pressed: ({})
    property string last: ""
    property real holdProgress: 0
    exclusive: testing
    hints: testing ? [{ key: "B", text: "Mantener: terminar la prueba" }] : []

    function startTest() {
        pressed = {}
        last = ""
        testing = true
        testArea.forceActiveFocus()
    }

    function stopTest() {
        holdTimer.stop()
        holdProgress = 0
        testing = false
        Qt.callLater(function () { startButton.forceActiveFocus() })
    }

    function light(name) {
        var p = Object.assign({}, pressed)
        p[name] = true
        pressed = p
        last = name
    }

    function holdStart() {
        if (!holdTimer.running) {
            holdProgress = 0
            holdTimer.elapsed = 0
            holdTimer.start()
        }
    }

    function holdEnd() {
        holdTimer.stop()
        holdProgress = 0
    }

    // Navigation actions do nothing during the test: the raw button events
    // below light the buttons.
    function gamepadAction(action) {
        return testing
    }

    Connections {
        target: Backend
        function onButtonEvent(name) {
            if (!page.testing)
                return
            page.light(name)
            if (name === "B")
                page.holdStart()
        }
        function onButtonReleased(name) {
            if (page.testing && name === "B")
                page.holdEnd()
        }
    }

    Timer {
        id: holdTimer
        property int elapsed: 0
        interval: 50
        repeat: true
        onTriggered: {
            elapsed += interval
            page.holdProgress = Math.min(1, elapsed / page.holdMs)
            if (elapsed >= page.holdMs)
                page.stopTest()
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
        subtitle: "Abre los ajustes de Bluetooth de Plasma"
        iconPath: Icons.bluetooth
        tint: Theme.blue
        chevron: true
        enabled: !page.testing
        onClicked: Backend.openBluetoothSettings()
    }

    SectionLabel { text: "Probar botones" }

    Card {
        Layout.fillWidth: true
        color: Theme.surfaceAlt
        highlighted: page.testing

        // Receives the keys Steam's desktop layout sends for some buttons
        // (arrows, Enter, Esc), so they light up too.
        Item {
            id: testArea
            Layout.fillWidth: true
            implicitHeight: 0
            activeFocusOnTab: false
            Keys.onPressed: function (event) {
                if (!page.testing)
                    return
                var map = {}
                map[Qt.Key_Up] = "Arriba"
                map[Qt.Key_Down] = "Abajo"
                map[Qt.Key_Left] = "Izquierda"
                map[Qt.Key_Right] = "Derecha"
                map[Qt.Key_Return] = "A"
                map[Qt.Key_Enter] = "A"
                map[Qt.Key_Escape] = "B"
                var name = map[event.key]
                if (name && !event.isAutoRepeat) {
                    page.light(name)
                    if (name === "B")
                        page.holdStart()
                }
                event.accepted = true
            }
            Keys.onReleased: function (event) {
                if (page.testing && event.key === Qt.Key_Escape && !event.isAutoRepeat)
                    page.holdEnd()
                event.accepted = page.testing
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Label {
                Layout.fillWidth: true
                text: !page.testing ? "Comprueba que todos los botones responden, también L1, R1 y B."
                    : page.last === "" ? "Pulsa los botones del mando: se iluminan al detectarlos."
                    : "Último: " + page.last
                color: Theme.textMuted
                font.pixelSize: Theme.fontBody
                wrapMode: Text.WordWrap
            }
            OButton {
                id: startButton
                visible: !page.testing
                kind: "primary"
                text: "Empezar la prueba"
                iconPath: Icons.gamepad
                onClicked: page.startTest()
            }
            OButton {
                visible: page.testing
                text: "Terminar"
                focusPolicy: Qt.NoFocus
                onClicked: page.stopTest()
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 10
            opacity: page.testing ? 1 : 0.5
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

        // Holding B: progress until the test ends
        ColumnLayout {
            visible: page.testing
            Layout.fillWidth: true
            spacing: 6
            Label {
                text: page.holdProgress > 0 ? "Sigue manteniendo B…" : "Mantén B pulsado para terminar"
                color: page.holdProgress > 0 ? Theme.amber : Theme.textFaint
                font.pixelSize: Theme.fontSmall
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 6
                radius: 3
                color: Theme.border
                Rectangle {
                    width: parent.width * page.holdProgress
                    height: parent.height
                    radius: 3
                    color: Theme.amber
                }
            }
        }

        Label {
            Layout.fillWidth: true
            text: "Si un botón no se ilumina, puede que la configuración de mando de Steam para el escritorio lo esté usando para otra cosa."
            color: Theme.textFaint
            font.pixelSize: Theme.fontSmall
            wrapMode: Text.WordWrap
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

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.ocelado.hello

// First-boot assistant. Each step can be skipped; the last one asks when
// the app should open by itself from now on.
PageBase {
    id: page
    margin: Backend.handheld ? 0 : 48

    readonly property var steps: Backend.gameModeEdition
        ? ["Bienvenida", "Actualizar", "Kernel", "Decky", "Apps", "Listo"]
        : ["Bienvenida", "Actualizar", "Kernel", "Apps", "Listo"]
    property int index: 0
    readonly property string step: steps[index]
    property string autostart: "news"
    property var apps: []

    function next() {
        if (index < steps.length - 1) {
            index += 1
            Qt.callLater(focusPrimary)
        }
    }
    function back() {
        if (index > 0) {
            index -= 1
            Qt.callLater(focusPrimary)
        }
    }
    function finish() {
        Backend.setAutostart(autostart)
        Backend.finishFirstRun()
        page.navigate("welcome")
    }
    function focusPrimary() { primary.forceActiveFocus() }

    function gamepadAction(action) {
        if (action === "back") {
            back()
            return true
        }
        return false
    }

    Component.onCompleted: Qt.callLater(focusPrimary)

    // Step chips
    Flow {
        Layout.fillWidth: true
        spacing: 10
        Repeater {
            model: page.steps
            delegate: Rectangle {
                required property string modelData
                required property int index
                readonly property bool done: index < page.index
                readonly property bool here: index === page.index
                width: chipLabel.implicitWidth + 28
                height: 36
                radius: 18
                color: here ? Theme.accent : (done ? Theme.accentSoft : Theme.surface)
                Label {
                    id: chipLabel
                    anchors.centerIn: parent
                    text: (parent.done ? "✓ " : "") + parent.modelData
                    color: parent.here ? Theme.accentInk : (parent.done ? Theme.accentSoftText : Theme.textMuted)
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.maximumWidth: 860
        Layout.topMargin: Theme.handheld ? 8 : 24
        spacing: Theme.handheld ? 20 : 28

        // Logo and step title
        RowLayout {
            Layout.fillWidth: true
            spacing: 28
            Image {
                source: Theme.logo
                readonly property int side: Theme.handheld ? 150 : 130
                sourceSize.width: side
                sourceSize.height: side
            }
            ColumnLayout {
            Layout.fillWidth: true
            spacing: 10
            Label {
                Layout.fillWidth: true
                text: page.step === "Bienvenida" ? "Te damos la bienvenida a Ocelado"
                    : page.step === "Actualizar" ? "Pon el sistema al día"
                    : page.step === "Kernel" ? "Tu kernel"
                    : page.step === "Decky" ? "Plugins para el Modo Juego"
                    : page.step === "Apps" ? "Algunas apps útiles"
                    : "¡Todo listo!"
                color: Theme.text
                font.pixelSize: Theme.fontHero
                font.weight: Font.Bold
                wrapMode: Text.WordWrap
            }
            Label {
                Layout.fillWidth: true
                text: page.step === "Bienvenida" ? "Te llevará un par de minutos. Puedes saltarte cualquier paso y hacerlo luego desde la app."
                    : page.step === "Actualizar" ? "Se descarga en segundo plano y se aplica al reiniciar."
                    : page.step === "Kernel" ? "Ocelado trae dos. Puedes cambiar cuando quieras desde Kernel y arranque."
                    : page.step === "Decky" ? "Decky añade menús al acceso rápido (···) del Modo Juego."
                    : page.step === "Apps" ? "Desde Flathub. Marca las que quieras o sigue sin instalar nada."
                    : "Una última cosa antes de empezar."
                color: Theme.textSoft
                font.pixelSize: Theme.handheld ? 18 : 16
                wrapMode: Text.WordWrap
            }
            }
        }

        // The step content
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.gap

            // Actualizar
            ListRow {
                visible: page.step === "Actualizar"
                Layout.fillWidth: true
                text: Backend.busy ? "Actualizando…" : (Backend.rebootPending ? "Actualización preparada" : "Actualizar ahora")
                subtitle: Backend.rebootPending ? "Se aplicará la próxima vez que reinicies" : "Sistema y apps Flatpak"
                iconPath: Icons.updates
                enabled: !Backend.busy && !Backend.rebootPending
                badge: Backend.rebootPending ? "Listo" : ""
                badgeTone: "green"
                onClicked: Backend.updateSystem()
            }

            // Kernel
            ColumnLayout {
                visible: page.step === "Kernel"
                Layout.fillWidth: true
                spacing: Theme.gap
                InfoTile {
                    Layout.fillWidth: true
                    label: "En uso"
                    value: (Backend.kernelFlavor === "ogc" ? "OGC" : Backend.kernelFlavor === "tkg" ? "linux-tkg" : "Otro") + " · " + Backend.kernelRelease
                }
                Label {
                    Layout.fillWidth: true
                    text: "OGC está pensado para portátiles de juego (mandos, TDP, pantallas). linux-tkg, para un escritorio fluido. GRUB arranca siempre el último que usaste."
                    color: Theme.textMuted
                    font.pixelSize: Theme.fontBody
                    wrapMode: Text.WordWrap
                }
            }

            // Decky
            ListRow {
                visible: page.step === "Decky"
                Layout.fillWidth: true
                text: Backend.deckyInstalled ? "Decky ya está instalado" : "Instalar Decky Loader"
                subtitle: "Con su instalador oficial"
                iconPath: Icons.decky
                tint: Theme.blue
                enabled: !Backend.deckyInstalled && !Backend.busy
                badge: Backend.deckyInstalled ? "Instalado" : ""
                badgeTone: "green"
                onClicked: Backend.installDecky()
            }

            // Apps
            Repeater {
                model: page.step === "Apps"
                       ? JSON.parse(Backend.appsJson).filter(function (a) { return !a.installed }).slice(0, 4)
                       : []
                delegate: ListRow {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.name
                    subtitle: modelData.description
                    letter: modelData.name.charAt(0)
                    tint: Theme.blue
                    trailing: "switch"
                    on: page.apps.indexOf(modelData.id) >= 0
                    onClicked: {
                        var s = page.apps.slice()
                        var i = s.indexOf(modelData.id)
                        if (i >= 0) s.splice(i, 1); else s.push(modelData.id)
                        page.apps = s
                    }
                }
            }

            // Listo: when to open by itself
            Label {
                visible: page.step === "Listo"
                Layout.fillWidth: true
                text: "¿Cuándo quieres ver esta app?"
                color: Theme.text
                font.pixelSize: Theme.handheld ? 24 : 20
                font.weight: Font.Bold
            }
            Repeater {
                model: page.step === "Listo" ? [
                    { mode: "always", text: "Siempre al iniciar", sub: "Se abre cada vez que entras" },
                    { mode: "news", text: "Solo cuando haya novedades", sub: "Tras una actualización con cambios" },
                    { mode: "never", text: "Nunca", sub: "La abres tú desde el menú de aplicaciones" }
                ] : []
                delegate: ListRow {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.text
                    subtitle: modelData.sub
                    trailing: "radio"
                    on: page.autostart === modelData.mode
                    badge: modelData.mode === "news" ? "Recomendado" : ""
                    badgeTone: "green"
                    onClicked: page.autostart = modelData.mode
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 12
                spacing: 10
                OButton {
                    visible: page.index > 0
                    text: "Atrás"
                    onClicked: page.back()
                }
                Item { Layout.fillWidth: true }
                OButton {
                    id: primary
                    kind: "primary"
                    text: page.step === "Bienvenida" ? "Empezar"
                        : page.step === "Listo" ? "Empezar a usar Ocelado"
                        : page.step === "Apps" && page.apps.length > 0 ? "Instalar y seguir"
                        : "Siguiente"
                    onClicked: {
                        if (page.step === "Apps" && page.apps.length > 0) {
                            Backend.installApps(JSON.stringify(page.apps))
                            page.apps = []
                        }
                        if (page.step === "Listo")
                            page.finish()
                        else
                            page.next()
                    }
                }
            }
        }
    }
}

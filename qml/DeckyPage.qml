import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.ocelado.hello

PageBase {
    id: page
    title: "Decky"
    description: "Cargador de plugins para el Modo Juego. Añade menús al acceso rápido (botón ···) para temas, carátulas o traer juegos de otras tiendas."
    hints: [{ key: "Y", text: "Instalar" }]

    readonly property var plugins: JSON.parse(Backend.pluginsJson)
    property var selected: ["unifideck"]

    function isSelected(id) { return selected.indexOf(id) >= 0 }
    function toggle(id) {
        var s = selected.slice()
        var i = s.indexOf(id)
        if (i >= 0) s.splice(i, 1); else s.push(id)
        selected = s
    }
    // Selected plugins that can be installed and are not installed yet.
    readonly property var toInstall: plugins.filter(function (p) {
        return p.installable && !p.installed && page.isSelected(p.id)
    }).map(function (p) { return p.id })

    function install() {
        if (Backend.deckyInstalled && toInstall.length > 0)
            Backend.installPlugins(JSON.stringify(toInstall))
    }

    function gamepadAction(action) {
        if (action === "y") {
            install()
            return true
        }
        return false
    }

    Card {
        Layout.fillWidth: true
        RowLayout {
            Layout.fillWidth: true
            spacing: 18
            Rectangle {
                implicitWidth: Theme.handheld ? 56 : 52
                implicitHeight: implicitWidth
                radius: 12
                color: Theme.surfaceHigh
                Icon { anchors.centerIn: parent; path: Icons.decky; color: Theme.accent; size: Theme.iconSize + 6 }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                RowLayout {
                    spacing: 10
                    Label {
                        text: "Decky Loader"
                        color: Theme.text
                        font.pixelSize: Theme.fontLarge
                        font.weight: Font.DemiBold
                    }
                    Badge {
                        text: Backend.deckyInstalled ? "Instalado" : "No instalado"
                        tone: Backend.deckyInstalled ? "green" : "neutral"
                    }
                }
                Label {
                    Layout.fillWidth: true
                    text: Backend.inGameMode
                          ? "Se instala desde el Modo Escritorio, con su instalador oficial."
                          : "Se abre el instalador oficial en un terminal. Al terminar, vuelve al Modo Juego."
                    color: Theme.textMuted
                    font.pixelSize: Theme.fontSmall
                    wrapMode: Text.WordWrap
                }
            }
            OButton {
                visible: !Backend.inGameMode
                kind: Backend.deckyInstalled ? "secondary" : "primary"
                text: Backend.deckyInstalled ? "Actualizar Decky" : "Instalar Decky Loader"
                onClicked: Backend.installDecky()
            }
        }
    }

    SectionLabel { text: "Módulos recomendados" }

    Repeater {
        model: page.plugins
        delegate: ListRow {
            required property var modelData
            Layout.fillWidth: true
            text: modelData.name
            subtitle: modelData.description + (modelData.note !== "" ? "\n" + modelData.note : "")
            letter: modelData.name.charAt(0)
            tint: modelData.installable ? Theme.blue : "#c7b6f0"
            badge: modelData.installed ? "Instalado" : modelData.source
            badgeTone: modelData.installed ? "green" : (modelData.installable ? "blue" : "neutral")
            trailing: modelData.installable && !modelData.installed ? "switch" : "none"
            on: page.isSelected(modelData.id)
            enabled: modelData.installable && !modelData.installed
            onClicked: page.toggle(modelData.id)
        }
    }

    Label {
        Layout.fillWidth: true
        text: "Los de la tienda de Decky se instalan desde el propio Decky, en el menú de acceso rápido."
        color: Theme.textFaint
        font.pixelSize: Theme.fontSmall
        wrapMode: Text.WordWrap
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Label {
            Layout.fillWidth: true
            visible: !Backend.deckyInstalled
            text: "Instala primero Decky Loader."
            color: Theme.textMuted
            font.pixelSize: Theme.fontSmall
        }
        Item { Layout.fillWidth: Backend.deckyInstalled }
        OButton {
            kind: "primary"
            text: "Instalar seleccionados (" + page.toInstall.length + ")"
            enabled: Backend.deckyInstalled && page.toInstall.length > 0 && !Backend.busy
            onClicked: page.install()
        }
    }
}

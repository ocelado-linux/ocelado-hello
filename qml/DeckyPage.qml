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
    // Selected plugins not installed yet.
    readonly property var toInstall: plugins.filter(function (p) {
        return !p.installed && page.isSelected(p.id)
    }).map(function (p) { return p.id })
    readonly property bool updateAvailable: Backend.deckyInstalled && Backend.deckyLatest !== ""
                                            && Backend.deckyVersion !== Backend.deckyLatest

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
                        text: !Backend.deckyInstalled ? "No instalado"
                            : Backend.deckyVersion !== "" ? "Instalado · " + Backend.deckyVersion : "Instalado"
                        tone: Backend.deckyInstalled ? "green" : "neutral"
                    }
                    Badge {
                        visible: Backend.deckyInstalled && !page.updateAvailable && Backend.deckyLatest !== ""
                        text: "Al día"
                        tone: "green"
                    }
                }
                Label {
                    Layout.fillWidth: true
                    text: !Backend.deckyInstalled ? "Con su instalador oficial."
                        : Backend.deckyLatest === "" ? "No se pudo comprobar si hay versión nueva."
                        : page.updateAvailable ? "Hay una versión nueva: " + Backend.deckyLatest + "."
                        : "Tienes la última versión."
                    color: Theme.textMuted
                    font.pixelSize: Theme.fontSmall
                    wrapMode: Text.WordWrap
                }
            }
            OButton {
                visible: !Backend.deckyInstalled || page.updateAvailable || Backend.deckyLatest === ""
                kind: page.updateAvailable || !Backend.deckyInstalled ? "primary" : "secondary"
                enabled: !Backend.busy
                text: !Backend.deckyInstalled ? "Instalar Decky Loader"
                    : page.updateAvailable ? "Actualizar a " + Backend.deckyLatest : "Reinstalar"
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
            tint: modelData.id === "unifideck" ? Theme.blue : "#c7b6f0"
            badge: modelData.installed ? "Instalado" : modelData.source
            badgeTone: modelData.installed ? "green" : (modelData.id === "unifideck" ? "blue" : "neutral")
            trailing: modelData.installed ? "none" : "switch"
            on: page.isSelected(modelData.id)
            enabled: !modelData.installed && Backend.deckyInstalled
            onClicked: page.toggle(modelData.id)
        }
    }

    Label {
        Layout.fillWidth: true
        text: "Se instalan desde aquí y aparecen en el menú de acceso rápido (···) del Modo Juego."
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

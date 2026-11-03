import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.ocelado.hello

PageBase {
    id: page
    title: "Aplicaciones"
    description: "Una selección de apps de Flathub que funcionan bien en Ocelado. Marca las que quieras e instálalas de una vez."
    hints: [{ key: "Y", text: "Instalar" }]

    readonly property var apps: JSON.parse(Backend.appsJson)
    readonly property var categories: {
        var seen = []
        for (var i = 0; i < apps.length; ++i)
            if (seen.indexOf(apps[i].category) < 0)
                seen.push(apps[i].category)
        return seen
    }
    property var selected: []

    function isSelected(id) { return selected.indexOf(id) >= 0 }
    function toggle(id) {
        var s = selected.slice()
        var i = s.indexOf(id)
        if (i >= 0) s.splice(i, 1); else s.push(id)
        selected = s
    }
    readonly property var toInstall: apps.filter(function (a) {
        return !a.installed && page.isSelected(a.id)
    }).map(function (a) { return a.id })

    function install() {
        if (toInstall.length > 0) {
            Backend.installApps(JSON.stringify(toInstall))
            selected = []
        }
    }

    function gamepadAction(action) {
        if (action === "y") {
            install()
            return true
        }
        return false
    }

    Label {
        visible: page.apps.length === 0
        text: "Comprobando qué apps tienes…"
        color: Theme.textMuted
        font.pixelSize: Theme.fontBody
    }

    Repeater {
        model: page.categories
        delegate: ColumnLayout {
            id: group
            required property string modelData
            Layout.fillWidth: true
            spacing: Theme.gap

            SectionLabel { text: group.modelData }

            GridLayout {
                Layout.fillWidth: true
                columns: page.width > 760 ? 2 : 1
                columnSpacing: Theme.gap
                rowSpacing: Theme.gap
                Repeater {
                    model: page.apps.filter(function (a) { return a.category === group.modelData })
                    delegate: ListRow {
                        required property var modelData
                        Layout.fillWidth: true
                        text: modelData.name
                        subtitle: modelData.description
                        letter: modelData.name.charAt(0)
                        tint: Theme.blue
                        badge: modelData.bundled ? "Incluida" : (modelData.installed ? "Instalada" : "")
                        badgeTone: "green"
                        trailing: modelData.installed ? "none" : "switch"
                        on: page.isSelected(modelData.id)
                        enabled: !modelData.installed
                        onClicked: page.toggle(modelData.id)
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Label {
            Layout.fillWidth: true
            text: "Se instalan desde Flathub y se actualizan con el resto de apps."
            color: Theme.textFaint
            font.pixelSize: Theme.fontSmall
            wrapMode: Text.WordWrap
        }
        OButton {
            kind: "primary"
            text: "Instalar seleccionadas (" + page.toInstall.length + ")"
            enabled: page.toInstall.length > 0 && !Backend.busy
            onClicked: page.install()
        }
    }
}

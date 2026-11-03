import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.ocelado.hello

PageBase {
    id: page
    title: "Actualizaciones"
    description: "El sistema se actualiza en una instantánea nueva sin tocar la que estás usando. Si algo falla, puedes volver atrás."

    readonly property var snapshots: JSON.parse(Backend.snapshotsJson)
    readonly property var active: {
        for (var i = 0; i < snapshots.length; ++i)
            if (snapshots[i].active)
                return snapshots[i]
        return null
    }
    // The newest snapshot older than the running one.
    readonly property var previous: {
        if (!active)
            return null
        for (var i = 0; i < snapshots.length; ++i)
            if (snapshots[i].number < active.number)
                return snapshots[i]
        return null
    }

    function askRollback(snap) {
        page.confirm("¿Volver a la instantánea " + snap.number + "?",
                     "El sistema arrancará como estaba el " + snap.date + ". Tus archivos, juegos y apps Flatpak no cambian. Después hay que reiniciar.",
                     "Volver a esta", true,
                     function () { Backend.rollback(snap.number) })
    }

    Component.onCompleted: Backend.loadSnapshots()

    // Status
    Card {
        Layout.fillWidth: true
        RowLayout {
            Layout.fillWidth: true
            spacing: 18
            Rectangle {
                implicitWidth: Theme.handheld ? 60 : 52
                implicitHeight: implicitWidth
                radius: width / 2
                color: Backend.rebootPending ? Theme.blueSoft : Theme.accentSoft
                Icon {
                    anchors.centerIn: parent
                    path: Backend.rebootPending ? Icons.power : Icons.updates
                    color: Backend.rebootPending ? Theme.blueSoftText : Theme.accentSoftText
                    size: Theme.iconSize
                    strokeWidth: 2
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Label {
                    Layout.fillWidth: true
                    text: Backend.rebootPending ? "Hay cambios esperando un reinicio" : "Busca e instala actualizaciones"
                    color: Theme.text
                    font.pixelSize: Theme.fontLarge
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }
                Label {
                    Layout.fillWidth: true
                    text: Backend.rebootPending
                          ? "La próxima vez que arranques se usará la instantánea nueva."
                          : "Sistema y apps Flatpak. No se aplica nada hasta que reinicies."
                    color: Theme.textMuted
                    font.pixelSize: Theme.fontSmall
                    wrapMode: Text.WordWrap
                }
            }
            OButton {
                visible: Backend.rebootPending
                kind: "primary"
                text: "Reiniciar"
                iconPath: Icons.power
                onClicked: Backend.reboot()
            }
            OButton {
                visible: !Backend.rebootPending
                kind: "primary"
                enabled: !Backend.busy
                text: "Actualizar ahora"
                onClicked: Backend.updateSystem()
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: page.width > 760 ? 2 : 1
        columnSpacing: Theme.gap
        rowSpacing: Theme.gap
        ListRow {
            Layout.fillWidth: true
            text: "Actualizar en segundo plano"
            subtitle: "Se aplica al reiniciar, nunca a mitad de partida"
            iconPath: Icons.updates
            tint: Theme.blue
            trailing: "switch"
            on: Backend.autoUpdates
            onClicked: Backend.changeAutoUpdates(!Backend.autoUpdates)
        }
        ListRow {
            Layout.fillWidth: true
            enabled: !Backend.busy
            text: "Actualizar solo las apps"
            subtitle: "Las apps Flatpak se actualizan aparte del sistema"
            iconPath: Icons.apps
            tint: Theme.amber
            onClicked: Backend.updateApps()
        }
    }

    SectionLabel { text: "Instantáneas" }

    Rectangle {
        visible: page.previous !== null
        Layout.fillWidth: true
        implicitHeight: rollbackRow.implicitHeight + 32
        radius: Theme.radius
        color: Theme.amberSoft
        border.color: Theme.amberBorder
        RowLayout {
            id: rollbackRow
            anchors.fill: parent
            anchors.margins: 16
            anchors.leftMargin: 20
            spacing: 16
            Icon { path: Icons.rollback; color: Theme.amber; size: Theme.iconSize }
            Label {
                Layout.fillWidth: true
                text: "¿Algo dejó de funcionar tras actualizar? Vuelve a la instantánea anterior y reinicia."
                color: Theme.amberText
                font.pixelSize: Theme.fontBody
                wrapMode: Text.WordWrap
            }
            OButton {
                kind: "warning"
                text: "Volver a la anterior"
                enabled: !Backend.busy
                onClicked: page.askRollback(page.previous)
            }
        }
    }

    Label {
        visible: !Backend.snapshotsLoaded
        Layout.fillWidth: true
        text: "Cargando instantáneas…"
        color: Theme.textMuted
        font.pixelSize: Theme.fontBody
    }

    Repeater {
        model: page.snapshots.slice(0, 8)
        delegate: ListRow {
            required property var modelData
            Layout.fillWidth: true
            text: "Instantánea " + modelData.number
            subtitle: modelData.date + (modelData.description !== "" ? " · " + modelData.description : "")
            letter: "#"
            tint: modelData.active ? Theme.accent : Theme.textFaint
            badge: modelData.active ? "En uso" : (modelData.default ? "Al reiniciar" : "")
            badgeTone: modelData.active ? "green" : "blue"
            chevron: !modelData.active && !modelData.default
            enabled: !Backend.busy
            onClicked: {
                if (!modelData.active && !modelData.default)
                    page.askRollback(modelData)
            }
        }
    }

    Label {
        Layout.fillWidth: true
        text: "También puedes elegir una instantánea en el menú de GRUB al encender."
        color: Theme.textFaint
        font.pixelSize: Theme.fontSmall
        wrapMode: Text.WordWrap
    }
}

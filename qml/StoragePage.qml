import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.ocelado.hello

PageBase {
    id: page
    title: "Almacenamiento"
    description: "Prepara tarjetas microSD o discos externos para tus juegos."

    readonly property var disks: JSON.parse(Backend.disksJson)

    Component.onCompleted: Backend.refreshStorage()

    function diskName(d) {
        if (d.system)
            return "Disco interno"
        if (d.name.indexOf("mmcblk") === 0)
            return "Tarjeta microSD"
        return "Disco externo"
    }

    function usage(d) {
        var used = 0, size = 0
        for (var i = 0; i < d.mounts.length; ++i) {
            used += d.mounts[i].used
            size += d.mounts[i].size
        }
        return { used: used, size: size }
    }

    function askFormat(d) {
        page.confirm("¿Preparar " + diskName(d).toLowerCase() + " para juegos?",
                     "Se borra TODO lo que tenga (" + Theme.bytes(d.size) + "). Quedará con formato ext4, como en SteamOS.",
                     "Borrar y preparar", true,
                     function () { Backend.formatDisk(d.path) })
    }

    Label {
        visible: page.disks.length === 0
        text: "Buscando discos…"
        color: Theme.textMuted
        font.pixelSize: Theme.fontBody
    }

    Repeater {
        model: page.disks
        delegate: Card {
            id: card
            required property var modelData
            readonly property var use: page.usage(modelData)
            Layout.fillWidth: true
            highlighted: modelData.removable && !modelData.steam_library

            RowLayout {
                Layout.fillWidth: true
                spacing: 14
                Icon {
                    path: card.modelData.system ? Icons.storage : Icons.sdcard
                    color: card.modelData.system ? Theme.accent : Theme.blue
                    size: Theme.iconSize
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label {
                        Layout.fillWidth: true
                        text: page.diskName(card.modelData)
                        color: Theme.text
                        font.pixelSize: Theme.fontLarge
                        font.weight: Font.DemiBold
                    }
                    Label {
                        Layout.fillWidth: true
                        text: Theme.bytes(card.modelData.size)
                              + (card.modelData.model !== "" ? " · " + card.modelData.model : "")
                              + (card.modelData.fstypes.length > 0 ? " · " + card.modelData.fstypes.join(", ") : " · sin formato")
                        color: Theme.textMuted
                        font.pixelSize: Theme.fontSmall
                        elide: Text.ElideRight
                    }
                }
                Badge {
                    visible: card.modelData.steam_library
                    text: "Biblioteca de Steam"
                    tone: "green"
                }
                Badge {
                    visible: card.modelData.system
                    text: "Sistema"
                }
            }

            ColumnLayout {
                visible: card.use.size > 0
                Layout.fillWidth: true
                spacing: 6
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Theme.handheld ? 10 : 8
                    radius: height / 2
                    color: Theme.border
                    Rectangle {
                        width: parent.width * Math.min(1, card.use.used / Math.max(1, card.use.size))
                        height: parent.height
                        radius: height / 2
                        color: card.modelData.system ? Theme.accent : Theme.blue
                    }
                }
                Label {
                    text: Theme.bytes(card.use.used) + " usados de " + Theme.bytes(card.use.size)
                    color: Theme.textFaint
                    font.pixelSize: Theme.fontSmall
                }
            }

            RowLayout {
                visible: card.modelData.removable
                spacing: 10
                OButton {
                    kind: card.modelData.steam_library ? "secondary" : "primary"
                    text: "Preparar para juegos"
                    enabled: !Backend.busy
                    onClicked: page.askFormat(card.modelData)
                }
                OButton {
                    visible: card.modelData.mounts.length > 0
                    text: "Expulsar"
                    iconPath: Icons.eject
                    enabled: !Backend.busy
                    onClicked: Backend.ejectDisk(card.modelData.path)
                }
            }

            Label {
                visible: card.modelData.removable && !card.modelData.steam_library && card.modelData.mounts.length > 0
                Layout.fillWidth: true
                text: "Si ya tiene juegos de otra Deck, no hace falta formatearla: añádela en Steam › Ajustes › Almacenamiento."
                color: Theme.textFaint
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.WordWrap
            }
        }
    }

    OButton {
        text: "Volver a buscar"
        onClicked: Backend.refreshStorage()
    }
}

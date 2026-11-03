import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.ocelado.hello

PageBase {
    id: page
    readonly property string kernelName: Backend.kernelFlavor === "ogc" ? "OGC"
                                       : Backend.kernelFlavor === "tkg" ? "linux-tkg" : "otro"

    Card {
        Layout.fillWidth: true
        color: Theme.surfaceAlt
        padding: Theme.handheld ? 28 : 28

        RowLayout {
            Layout.fillWidth: true
            spacing: 28
            Image {
                source: Theme.logo
                sourceSize.width: Theme.handheld ? 170 : 140
                sourceSize.height: Theme.handheld ? 170 : 140
                Layout.alignment: Qt.AlignTop
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
                Label {
                    text: (Backend.version !== "" ? "Ocelado Linux " + Backend.version + " · " : "") + Backend.editionName
                    color: Theme.accentSoftText
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.DemiBold
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 0.6
                }
                Label {
                    text: "Te damos la bienvenida"
                    color: Theme.text
                    font.pixelSize: Theme.fontHero
                    font.weight: Font.Bold
                }
                Label {
                    Layout.fillWidth: true
                    text: Backend.gameModeEdition
                          ? "Base openSUSE Tumbleweed inmutable con el Modo Juego de Steam y Plasma para el escritorio. Aquí tienes lo esencial para dejarlo a tu gusto."
                          : "Base openSUSE Tumbleweed inmutable con KDE Plasma y kernel linux-tkg para jugar en tu PC. Aquí tienes lo esencial para empezar."
                    color: Theme.textSoft
                    font.pixelSize: Theme.handheld ? 18 : 15
                    wrapMode: Text.WordWrap
                }
                RowLayout {
                    spacing: 10
                    Layout.topMargin: 6
                    OButton {
                        visible: Backend.gameModeEdition && !Backend.inGameMode
                        kind: "primary"
                        text: "Volver al Modo Juego"
                        onClicked: Backend.switchToGameMode()
                    }
                    OButton {
                        visible: !Backend.gameModeEdition
                        kind: "primary"
                        text: "Explorar apps"
                        onClicked: page.navigate("apps")
                    }
                    OButton {
                        text: "Web del proyecto"
                        onClicked: Qt.openUrlExternally(Theme.projectUrl)
                    }
                }
            }
        }
    }

    SectionLabel { text: "Primeros pasos" }

    GridLayout {
        Layout.fillWidth: true
        columns: page.width > 760 ? 2 : 1
        columnSpacing: Theme.gap
        rowSpacing: Theme.gap

        ListRow {
            Layout.fillWidth: true
            text: "Actualizar el sistema"
            subtitle: "Se aplica en una instantánea nueva al reiniciar"
            iconPath: Icons.updates
            chevron: true
            onClicked: page.navigate("updates")
        }
        ListRow {
            visible: Backend.gameModeEdition
            Layout.fillWidth: true
            text: "Decky y módulos"
            subtitle: Backend.deckyInstalled ? "Decky instalado" : "Plugins para el Modo Juego"
            iconPath: Icons.decky
            tint: Theme.blue
            chevron: true
            onClicked: page.navigate("decky")
        }
        ListRow {
            Layout.fillWidth: true
            text: "Elegir kernel"
            subtitle: "En uso: " + page.kernelName
            iconPath: Icons.kernel
            tint: "#c7b6f0"
            chevron: true
            onClicked: page.navigate("kernel")
        }
        ListRow {
            Layout.fillWidth: true
            text: "Aplicaciones"
            subtitle: "Heroic, RetroDECK, Discord y más desde Flathub"
            iconPath: Icons.apps
            tint: Theme.amber
            chevron: true
            onClicked: page.navigate("apps")
        }
    }

    SectionLabel { text: "Tu sistema" }

    GridLayout {
        Layout.fillWidth: true
        columns: page.width > 760 ? 2 : 1
        columnSpacing: Theme.gap
        rowSpacing: Theme.gap
        InfoTile { Layout.fillWidth: true; label: "Base"; value: "openSUSE Tumbleweed (inmutable)" }
        InfoTile { Layout.fillWidth: true; label: "Kernel en uso"; value: page.kernelName + " · " + Backend.kernelRelease }
        InfoTile { Layout.fillWidth: true; label: "Dispositivo"; value: Backend.deviceName }
        InfoTile { Layout.fillWidth: true; label: "Sesión"; value: Backend.inGameMode ? "Modo Juego" : "Escritorio" }
    }
}

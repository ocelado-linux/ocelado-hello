import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.ocelado.hello

PageBase {
    id: page
    title: "Ayuda y comunidad"
    description: Backend.handheld
                 ? "Escribir con el mando es incómodo: crea el informe y sigue desde el móvil con el código QR."
                 : "Si algo no va bien, prepara un informe con un clic y compártelo en GitHub."

    property bool includeJournal: true
    property bool includeDecky: false

    GridLayout {
        Layout.fillWidth: true
        columns: page.width > 760 ? 2 : 1
        columnSpacing: Theme.gap
        rowSpacing: Theme.gap
        ListRow {
            Layout.fillWidth: true
            text: "Web del proyecto"
            subtitle: "Guías, novedades y descargas"
            iconPath: Icons.globe
            chevron: true
            onClicked: Qt.openUrlExternally(Theme.projectUrl)
        }
        ListRow {
            Layout.fillWidth: true
            text: "Fallos conocidos"
            subtitle: "Mira si ya está avisado antes de abrir uno nuevo"
            iconPath: Icons.bug
            tint: Theme.amber
            chevron: true
            onClicked: Qt.openUrlExternally("https://github.com/ocelado-linux/ocelado-hello/issues")
        }
    }

    SectionLabel { text: "Informar de un fallo" }

    Card {
        Layout.fillWidth: true
        color: Theme.surfaceAlt

        Label {
            text: "¿Qué ha pasado?"
            color: Theme.textSoft
            font.pixelSize: Theme.fontBody
            font.weight: Font.Medium
        }
        TextArea {
            id: desc
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.handheld ? 110 : 90
            placeholderText: "Por ejemplo: al volver al Modo Juego la pantalla se queda en negro"
            placeholderTextColor: Theme.textFaint
            wrapMode: TextEdit.Wrap
            color: Theme.text
            font.pixelSize: Theme.fontBody
            background: Rectangle {
                radius: 10
                color: Theme.window
                border.width: desc.activeFocus ? 2 : 1
                border.color: desc.activeFocus ? Theme.accent : Theme.borderStrong
            }
        }
        GridLayout {
            Layout.fillWidth: true
            columns: page.width > 760 ? 2 : 1
            columnSpacing: Theme.gap
            rowSpacing: Theme.gap
            ListRow {
                Layout.fillWidth: true
                text: "Registro de este arranque"
                subtitle: "journalctl, sin tu usuario ni el nombre del equipo"
                trailing: "switch"
                on: page.includeJournal
                onClicked: page.includeJournal = !page.includeJournal
            }
            ListRow {
                visible: Backend.gameModeEdition
                Layout.fillWidth: true
                text: "Registro de Decky"
                trailing: "switch"
                on: page.includeDecky
                onClicked: page.includeDecky = !page.includeDecky
            }
        }
        OButton {
            kind: "primary"
            text: "Crear informe"
            iconPath: Icons.bug
            enabled: !Backend.busy
            onClicked: Backend.createReport(desc.text, page.includeJournal, page.includeDecky)
        }
    }

    Card {
        visible: Backend.reportPath !== ""
        Layout.fillWidth: true
        highlighted: true

        RowLayout {
            Layout.fillWidth: true
            spacing: 24
            Rectangle {
                Layout.alignment: Qt.AlignTop
                implicitWidth: Theme.handheld ? 240 : 200
                implicitHeight: implicitWidth
                radius: 12
                color: "white"
                Image {
                    anchors.fill: parent
                    anchors.margins: 6
                    source: Backend.reportQr !== "" ? "data:image/svg+xml;utf8," + encodeURIComponent(Backend.reportQr) : ""
                    sourceSize.width: width
                    sourceSize.height: height
                    smooth: false
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
                Label {
                    Layout.fillWidth: true
                    text: "Sigue desde el móvil"
                    color: Theme.text
                    font.pixelSize: Theme.fontLarge
                    font.weight: Font.DemiBold
                }
                Label {
                    Layout.fillWidth: true
                    text: "Escanea el código: se abre un fallo nuevo en GitHub con la información del sistema ya puesta. Los registros completos están en:\n" + Backend.reportPath
                    color: Theme.textMuted
                    font.pixelSize: Theme.fontSmall
                    wrapMode: Text.WrapAnywhere
                }
                RowLayout {
                    spacing: 10
                    OButton {
                        text: "Abrir en el navegador"
                        iconPath: Icons.external
                        onClicked: Qt.openUrlExternally(Backend.reportUrl)
                    }
                    OButton {
                        text: "Abrir carpeta"
                        iconPath: Icons.folder
                        onClicked: Qt.openUrlExternally("file://" + Backend.reportPath.substring(0, Backend.reportPath.lastIndexOf("/")))
                    }
                }
            }
        }
    }
}

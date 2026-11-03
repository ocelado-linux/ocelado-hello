import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.ocelado.hello

// "Novedades en Ocelado X": release notes downloaded from the website.
Popup {
    id: dialog
    readonly property var release: Backend.newsJson !== "" ? JSON.parse(Backend.newsJson) : ({ title: "", items: [] })
    signal finished()

    function dismiss() {
        Backend.markNewsSeen()
        close()
        finished()
    }

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(parent.width - 48, Theme.handheld ? 760 : 600)
    height: Math.min(parent.height - 48, implicitHeight)
    modal: true
    focus: true
    padding: 0
    closePolicy: Popup.CloseOnEscape
    onClosed: if (Backend.newsAvailable) Backend.markNewsSeen()
    onOpened: okButton.forceActiveFocus()

    Overlay.modal: Rectangle { color: Qt.rgba(0.02, 0.03, 0.02, 0.6) }

    background: Rectangle {
        radius: 16
        color: Theme.window
        border.color: Theme.border
    }

    contentItem: ColumnLayout {
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: header.implicitHeight + 46
            color: Theme.surfaceAlt
            radius: 16
            RowLayout {
                id: header
                anchors.fill: parent
                anchors.margins: 23
                anchors.leftMargin: 28
                spacing: 18
                Image {
                    source: Theme.logo
                    sourceSize.width: Theme.handheld ? 88 : 72
                    sourceSize.height: Theme.handheld ? 88 : 72
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Label {
                        text: "Actualización instalada"
                        color: Theme.accentSoftText
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0.8
                    }
                    Label {
                        Layout.fillWidth: true
                        text: dialog.release.title !== "" ? dialog.release.title
                                                          : "Novedades en Ocelado " + Backend.version
                        color: Theme.text
                        font.pixelSize: Theme.handheld ? 30 : 25
                        font.weight: Font.Bold
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: items.implicitHeight + 44
            clip: true
            ColumnLayout {
                id: items
                x: 28
                y: 22
                width: dialog.width - 56
                spacing: 16
                Repeater {
                    model: dialog.release.items
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 14
                        Rectangle {
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: 7
                            implicitWidth: 8
                            implicitHeight: 8
                            radius: 4
                            color: Theme.accent
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Label {
                                Layout.fillWidth: true
                                text: modelData.title
                                color: Theme.text
                                font.pixelSize: Theme.fontLarge
                                font.weight: Font.DemiBold
                                wrapMode: Text.WordWrap
                            }
                            Label {
                                Layout.fillWidth: true
                                visible: modelData.text !== ""
                                text: modelData.text
                                color: Theme.textMuted
                                font.pixelSize: Theme.fontBody
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.border
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 18
            Layout.leftMargin: 28
            Layout.rightMargin: 28
            spacing: 10
            Label {
                Layout.fillWidth: true
                text: "Leído de la web de Ocelado en GitHub"
                color: Theme.textFaint
                font.pixelSize: 12
                elide: Text.ElideRight
            }
            OButton {
                visible: dialog.release.url !== undefined && dialog.release.url !== ""
                text: "Ver en la web"
                onClicked: Qt.openUrlExternally(dialog.release.url)
            }
            OButton {
                id: okButton
                kind: "primary"
                text: "Entendido"
                onClicked: dialog.dismiss()
            }
        }
    }
}

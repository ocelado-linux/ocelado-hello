import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.ocelado.hello

Rectangle {
    id: tile
    property string label
    property string value

    color: Theme.surface
    radius: 10
    border.color: Theme.border
    implicitHeight: col.implicitHeight + 28
    implicitWidth: 220

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 14
        anchors.leftMargin: 18
        spacing: 4
        Label { text: tile.label; color: Theme.textFaint; font.pixelSize: Theme.handheld ? 14 : 12 }
        Label {
            Layout.fillWidth: true
            text: tile.value
            color: Theme.text
            font.pixelSize: Theme.handheld ? 17 : 14
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
    }
}

import QtQuick
import QtQuick.Layouts
import org.ocelado.hello

// Rounded panel; children go into a ColumnLayout.
Rectangle {
    id: root
    default property alias content: column.data
    property alias spacing: column.spacing
    property int padding: Theme.pad
    property bool highlighted: false

    color: Theme.surface
    radius: Theme.radius
    border.width: highlighted ? 2 : 1
    border.color: highlighted ? Theme.accent : Theme.border
    implicitHeight: column.implicitHeight + padding * 2
    implicitWidth: column.implicitWidth + padding * 2

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: Theme.gap
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.ocelado.hello

// Scrollable page with a title and description. Children are laid out in a
// column below the header.
Flickable {
    id: page
    property string title: ""
    property string description: ""
    property int margin: Theme.handheld ? 0 : 36
    default property alias content: column.data
    /// Extra button hints for the handheld bar: [{ key: "Y", text: "Instalar" }]
    property var hints: []

    signal navigate(string pageId)
    /// Asks Main.qml to show the confirmation dialog; `callback` runs on OK.
    signal confirm(string title, string text, string action, bool danger, var callback)

    /// Page-specific gamepad handling; return true when handled.
    function gamepadAction(action) { return false }

    clip: true
    contentWidth: width
    contentHeight: column.implicitHeight + margin * 2
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

    // Scrolls so that `item` (a descendant) is fully visible.
    function ensureVisible(item) {
        if (!item || contentHeight <= height)
            return
        var p = item.mapToItem(column, 0, 0)
        var top = p.y + column.y
        var bottom = top + item.height
        if (top < contentY + 12)
            contentY = Math.max(0, top - 24)
        else if (bottom > contentY + height - 12)
            contentY = Math.min(contentHeight - height, bottom - height + 24)
    }

    ColumnLayout {
        id: column
        x: page.margin
        y: page.margin
        width: page.width - page.margin * 2
        spacing: Theme.handheld ? 16 : 24

        ColumnLayout {
            visible: page.title !== ""
            Layout.fillWidth: true
            spacing: 6
            Label {
                text: page.title
                color: Theme.text
                font.pixelSize: Theme.fontTitle
                font.weight: Font.Bold
            }
            Label {
                visible: page.description !== ""
                Layout.fillWidth: true
                Layout.maximumWidth: 680
                text: page.description
                color: Theme.textMuted
                font.pixelSize: Theme.handheld ? 17 : 15
                wrapMode: Text.WordWrap
            }
        }
    }
}

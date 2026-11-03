import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.ocelado.hello

// Large focusable row: leading icon or letter tile, title, subtitle and a
// trailing indicator (switch or radio), badge or chevron. Used for
// navigation lists, pickers and settings in both layouts.
//
// The indicator state comes from `on`; the row never toggles itself, the
// page decides in onClicked. That keeps mouse, keyboard and gamepad
// activation identical.
AbstractButton {
    id: row
    property string subtitle: ""
    property string iconPath: ""
    property string letter: ""
    property color tint: Theme.accent
    property string badge: ""
    property string badgeTone: "neutral"
    property bool chevron: false
    /// Trailing indicator: "none", "switch" or "radio"
    property string trailing: "none"
    property bool on: false

    focusPolicy: Qt.StrongFocus
    leftPadding: Theme.handheld ? 22 : 16
    rightPadding: leftPadding
    topPadding: 12
    bottomPadding: 12
    implicitHeight: Math.max(Theme.rowHeight, content.implicitHeight + topPadding + bottomPadding)
    implicitWidth: 320
    opacity: enabled ? 1 : 0.55

    Keys.onReturnPressed: row.clicked()
    Keys.onEnterPressed: row.clicked()

    background: Rectangle {
        readonly property bool marked: row.trailing !== "none" && row.on && !Theme.handheld
        radius: Theme.radius
        color: row.activeFocus && Theme.handheld ? Theme.surfaceHigh
             : row.hovered || row.down ? Theme.surfaceHigh : Theme.surface
        border.width: row.activeFocus ? (Theme.handheld ? 3 : 2) : (marked ? 2 : 1)
        border.color: row.activeFocus || marked ? Theme.accent : Theme.border
        Rectangle {
            // Soft halo around the focused row, like Steam's Big Picture
            visible: row.activeFocus && Theme.handheld
            anchors.fill: parent
            anchors.margins: -6
            radius: parent.radius + 6
            color: "transparent"
            border.width: 6
            border.color: Qt.rgba(0.56, 0.82, 0.44, 0.18)
        }
    }

    contentItem: RowLayout {
        id: content
        spacing: Theme.handheld ? 18 : 14

        Rectangle {
            visible: row.letter !== "" || row.iconPath !== ""
            Layout.preferredWidth: Theme.handheld ? 48 : 40
            Layout.preferredHeight: Layout.preferredWidth
            radius: 10
            color: Qt.rgba(row.tint.r, row.tint.g, row.tint.b, 0.14)
            Label {
                visible: row.letter !== ""
                anchors.centerIn: parent
                text: row.letter
                color: row.tint
                font.pixelSize: Theme.handheld ? 20 : 16
                font.weight: Font.Bold
            }
            Icon {
                visible: row.letter === "" && row.iconPath !== ""
                anchors.centerIn: parent
                path: row.iconPath
                color: row.tint
                size: Theme.iconSize
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Label {
                Layout.fillWidth: true
                text: row.text
                color: Theme.text
                font.pixelSize: Theme.handheld ? 20 : 15
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Label {
                Layout.fillWidth: true
                visible: row.subtitle !== ""
                text: row.subtitle
                color: Theme.textMuted
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.WordWrap
            }
        }

        Badge {
            visible: row.badge !== ""
            text: row.badge
            tone: row.badgeTone
        }

        // Switch
        Rectangle {
            visible: row.trailing === "switch"
            Layout.preferredWidth: Theme.handheld ? 56 : 44
            Layout.preferredHeight: Theme.handheld ? 32 : 26
            radius: height / 2
            color: row.on ? Theme.accent : "#33433b"
            Rectangle {
                width: parent.height - 6
                height: width
                radius: width / 2
                y: 3
                x: row.on ? parent.width - width - 3 : 3
                color: row.on ? Theme.accentInk : Theme.textMuted
                Behavior on x { NumberAnimation { duration: 120 } }
            }
        }

        // Radio
        Rectangle {
            visible: row.trailing === "radio"
            Layout.preferredWidth: Theme.handheld ? 28 : 22
            Layout.preferredHeight: Layout.preferredWidth
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: row.on ? Theme.accent : "#5a6b62"
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.45
                height: width
                radius: width / 2
                color: Theme.accent
                visible: row.on
            }
        }

        Icon {
            visible: row.chevron
            path: Icons.chevron
            color: Theme.textFaint
            size: Theme.handheld ? 22 : 18
            strokeWidth: 2
        }
    }
}

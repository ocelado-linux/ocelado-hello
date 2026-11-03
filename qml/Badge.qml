import QtQuick
import QtQuick.Controls
import org.ocelado.hello

// Small pill label. tone: "green", "blue", "neutral", "accent".
Rectangle {
    id: root
    property alias text: label.text
    property string tone: "neutral"

    implicitWidth: label.implicitWidth + (Theme.handheld ? 24 : 18)
    implicitHeight: label.implicitHeight + (Theme.handheld ? 10 : 6)
    radius: height / 2
    color: tone === "green" ? Theme.accentSoft
         : tone === "blue" ? Theme.blueSoft
         : tone === "accent" ? Theme.accent : "#2a2f2c"

    Label {
        id: label
        anchors.centerIn: parent
        font.pixelSize: Theme.handheld ? 14 : 12
        font.weight: Font.DemiBold
        color: root.tone === "green" ? Theme.accentSoftText
             : root.tone === "blue" ? Theme.blueSoftText
             : root.tone === "accent" ? Theme.accentInk : "#c3cec7"
    }
}

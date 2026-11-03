pragma Singleton
import QtQuick
import org.ocelado.hello

// Colours and sizes shared by both layouts. `handheld` scales everything for
// a 1280×800 screen used with a controller.
QtObject {
    readonly property bool handheld: Backend.handheld

    // Colours (Ocelado green on a dark ground)
    readonly property color ground: "#0b100d"
    readonly property color window: "#121a16"
    readonly property color chrome: "#0f1613"
    readonly property color surface: "#18221d"
    readonly property color surfaceAlt: "#16201b"
    readonly property color surfaceHigh: "#22302a"
    readonly property color border: "#2a3832"
    readonly property color borderStrong: "#3a4b42"
    readonly property color text: "#e8efe9"
    readonly property color textSoft: "#c9d6ce"
    readonly property color textMuted: "#a9b9af"
    readonly property color textFaint: "#9fb0a6"
    readonly property color accent: "#8fd16f"
    readonly property color accentInk: "#0e1411"
    readonly property color accentSoft: "#1f3a26"
    readonly property color accentSoftText: "#a6e08a"
    readonly property color blue: "#5fb0e8"
    readonly property color blueSoft: "#1d2b35"
    readonly property color blueSoftText: "#9ccdf0"
    readonly property color amber: "#f0c27a"
    readonly property color amberSoft: "#2a2418"
    readonly property color amberBorder: "#5a4a26"
    readonly property color amberText: "#f3e3c4"
    readonly property color danger: "#f09aa6"

    readonly property url logo: "qrc:/qt/qml/org/ocelado/hello/qml/assets/ocelado-logo.svg"
    readonly property url logoSmall: "qrc:/qt/qml/org/ocelado/hello/qml/assets/ocelado-logo-small.svg"
    readonly property string projectUrl: "https://github.com/ocelado-linux"

    // Sizes
    readonly property int fontSmall: handheld ? 15 : 13
    readonly property int fontBody: handheld ? 17 : 14
    readonly property int fontLarge: handheld ? 20 : 16
    readonly property int fontTitle: handheld ? 34 : 30
    readonly property int fontHero: handheld ? 42 : 36
    readonly property int rowHeight: handheld ? 80 : 60
    readonly property int buttonHeight: handheld ? 56 : 44
    readonly property int radius: handheld ? 14 : 12
    readonly property int pad: handheld ? 24 : 20
    readonly property int gap: handheld ? 14 : 12
    readonly property int iconSize: handheld ? 28 : 20
    readonly property int focusWidth: handheld ? 3 : 2

    /// 1500000000 → "1,5 GB" (decimal units, as disks are sold).
    function bytes(n) {
        if (!n || n <= 0)
            return "0 B"
        var units = ["B", "KB", "MB", "GB", "TB"]
        var i = Math.min(units.length - 1, Math.floor(Math.log(n) / Math.log(1000)))
        var v = n / Math.pow(1000, i)
        return v.toLocaleString(Qt.locale("es_ES"), "f", v < 10 && i > 0 ? 1 : 0) + " " + units[i]
    }
}

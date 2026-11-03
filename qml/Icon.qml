import QtQuick
import QtQuick.Shapes

// Stroke icon from SVG path data drawn on a 24×24 grid.
Item {
    id: root
    property string path
    property color color: "white"
    property real size: 20
    property real strokeWidth: 1.8

    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 24
        height: 24
        scale: root.size / 24
        transformOrigin: Item.TopLeft
        // Multisampling keeps the strokes smooth with the default renderer
        layer.enabled: true
        layer.samples: 4
        layer.smooth: true
        ShapePath {
            strokeColor: root.color
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.path }
        }
    }
}

import QtQuick
import qs
import qs.themes

StyledText {
    id: root

    property real fill: 0
    property int iconSize: Tokens.icon.md
    property int symbolWeight: 400
    property int grade: 0
    // property int grade: LightMode ? 0 : -25

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    textFormat: Text.PlainText
    renderType: Text.NativeRendering

    font.family: "Material Symbols Rounded"
    font.pixelSize: root.iconSize
    font.weight: Font.Normal
    color: Theme.color.m3onSurface

    font.variableAxes: ({
        "FILL": root.fill,
        "wght": root.symbolWeight,
        "GRAD": root.grade,
        "opsz": Math.max(20, Math.min(48, root.iconSize))
    })
}

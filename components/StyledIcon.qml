import QtQuick

import qs
import qs.themes

StyledText {
    id: root

    property real fillAmount: 0
    property int iconSize: Tokens.icon.md
    property int symbolWeight: Tokens.icon.weight
    property int grade: Theme.dark ? Tokens.icon.gradeDark : Tokens.icon.gradeLight

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    textFormat: Text.PlainText
    renderType: Text.NativeRendering

    font.family: "Material Symbols Rounded"
    font.pixelSize: root.iconSize
    font.weight: Font.Normal
    color: Theme.color.m3onSurface

    font.variableAxes: ({
        "FILL": root.fillAmount,
        "wght": root.symbolWeight,
        "GRAD": root.grade,
        "opsz": Math.max(20, Math.min(48, root.iconSize))
    })
}

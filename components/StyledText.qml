import QtQuick

import qs
import qs.themes

Text {
    id: root

    property bool animateTextChange: false
    property bool wrapText: false
    property bool elideText: false
    property bool animateFontSize: true

    renderType: Text.NativeRendering
    textFormat: Text.PlainText

    font.pixelSize: Tokens.fontSize.md
    font.weight: Tokens.font.regular
    font.family: Tokens.font.family

    color: Theme.color.m3onBackground

    elide: root.elideText ? Text.ElideRight : Text.ElideNone
    wrapMode: root.wrapText ? Text.Wrap : Text.NoWrap
    maximumLineCount: root.wrapText ? 0 : 1

    Behavior on font.pixelSize {
        enabled: root.animateFontSize

        Anim {}
    }

    Behavior on color {
        CAnim {}
    }

    Behavior on text {
        enabled: root.animateTextChange

        SequentialAnimation {
            Anim {
                target: root
                properties: "opacity,scale"
                to: 0
                duration: Tokens.animDuration.effectsFast
                easing.type: Easing.InCubic
            }
            PropertyAction {}
            ParallelAnimation {
                Anim {
                    target: root
                    property: "opacity"
                    to: 1
                    duration: Tokens.animDuration.effects
                }
                Anim {
                    target: root
                    property: "scale"
                    to: 1
                    duration: Tokens.animDuration.spatialFast
                }
            }
        }
    }
}

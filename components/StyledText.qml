import QtQuick
import qs
import qs.themes

Text {
    id: root

    property bool animateText: false
    property bool wrapText: false
    property bool elideText: false
    // Off when the owner animates size itself (e.g. scale), since pixel sizes step in whole pixels.
    property bool animateSize: true

    renderType: Text.NativeRendering
    textFormat: Text.PlainText

    font.pixelSize: Tokens.fontSize.md
    font.weight: Tokens.font.regular
    font.family: Tokens.font.font

    color: Theme.color.m3onBackground

    elide: elideText ? Text.ElideRight : Text.ElideNone
    wrapMode: wrapText ? Text.Wrap : Text.NoWrap
    maximumLineCount: wrapText ? 0 : 1

    // No overshoot: a bouncing size shifts layouts that depend on this text's height.
    Behavior on font.pixelSize {
        enabled: root.animateSize

        Anim {
            easing.type: Easing.OutCubic
        }
    }

    Behavior on color {
        CAnim {}
    }

    Behavior on text {
        enabled: root.animateText

        // Shrink + fade out, swap, then pop back in.
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
                    easing.type: Easing.OutCubic
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

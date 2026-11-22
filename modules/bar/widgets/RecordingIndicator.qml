import QtQuick

import qs
import qs.themes
import qs.services
import qs.components

// A breathing red dot while the screen is being captured; takes no space otherwise.
Reveal {
    id: root

    shown: HyprlandService.screencasting
    leadingGap: Tokens.spacing.md

    StyledRectangle {
        id: dot

        implicitWidth: Tokens.bar.workspaceDot
        implicitHeight: Tokens.bar.workspaceDot
        radius: Tokens.radius.full
        color: Theme.color.m3error

        SequentialAnimation on opacity {
            running: root.visible
            loops: Animation.Infinite

            Anim {
                to: 0.35
                duration: Tokens.animDuration.spatialSlow * 2
                easing.type: Easing.InOutSine
            }
            Anim {
                to: 1
                duration: Tokens.animDuration.spatialSlow * 2
                easing.type: Easing.InOutSine
            }
        }
    }
}

import QtQuick

import qs
import qs.config
import qs.themes
import qs.services
import qs.components

// The bar while the OSD is up: a draggable level slider, or an icon + message.
// Switching between slider and message, or to a different message, fades the old content out
// first and only then swaps, so the bar never resizes around content that is leaving or not there yet.
Item {
    id: root

    // What is drawn; trails OsdService until the old content has faded out.
    property bool shownIsLevel: false
    property string shownText: ""
    property string shownIcon: ""
    property real contentOpacity: 1

    // The slider keeps its last value and icon while it fades out to a message.
    property real levelValue: 0
    property string levelIcon: ""

    Binding {
        target: root
        property: "levelValue"
        value: OsdService.value
        when: OsdService.isLevel
        restoreMode: Binding.RestoreNone
    }

    Binding {
        target: root
        property: "levelIcon"
        value: OsdService.icon
        when: OsdService.isLevel
        restoreMode: Binding.RestoreNone
    }

    readonly property bool pending: OsdService.isLevel !== root.shownIsLevel
        || (!OsdService.isLevel && (OsdService.text !== root.shownText || OsdService.icon !== root.shownIcon))

    function syncShown() {
        root.shownIsLevel = OsdService.isLevel;
        root.shownText = OsdService.text;
        root.shownIcon = OsdService.icon;
    }

    Component.onCompleted: root.syncShown()

    onPendingChanged: {
        if (!root.pending)
            return;
        // Off screen there is nothing to fade: swap at once.
        if (!root.visible) {
            swap.stop();
            root.contentOpacity = 1;
            // Deferred: changing what `pending` reads from inside its own change handler loops.
            Qt.callLater(root.syncShown);
        } else if (!swap.running) {
            swap.restart();
        }
    }

    SequentialAnimation {
        id: swap

        Anim {
            target: root
            property: "contentOpacity"
            to: 0
            duration: Tokens.animDuration.effectsFast
            easing.type: Easing.InCubic
        }
        // Picks up the latest state if it changed during the fade.
        ScriptAction {
            script: root.syncShown()
        }
        Anim {
            target: root
            property: "contentOpacity"
            to: 1
            duration: Tokens.animDuration.effects
        }
    }

    // Follows the shown content; the bar resizes with it.
    implicitWidth: root.shownIsLevel ? slider.width : Math.min(Tokens.osd.maxMessageWidth, message.implicitWidth)
    implicitHeight: Config.bar.collapsedHeight

    // Only while seen: off screen the width snaps, so the OSD appears at its real size.
    Behavior on implicitWidth {
        enabled: root.visible

        Anim {
            duration: Tokens.animDuration.spatialFast
            easing.type: Easing.OutBack
        }
    }

    Slider {
        id: slider

        anchors.centerIn: parent
        value: root.levelValue
        icon: root.levelIcon
        interactive: OsdService.active && root.shownIsLevel
        opacity: root.shownIsLevel ? root.contentOpacity : 0
        visible: opacity > 0

        onMoved: value => OsdService.set(value)
        onStepped: direction => OsdService.step(direction)
        onPressedChanged: OsdService.hold(slider.pressed)
    }

    Row {
        id: message

        anchors.centerIn: parent
        spacing: Tokens.spacing.xs
        opacity: root.shownIsLevel ? 0 : root.contentOpacity
        visible: opacity > 0

        StyledIcon {
            id: messageIcon

            anchors.verticalCenter: parent.verticalCenter
            iconSize: Tokens.icon.md
            text: root.shownIcon
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, Tokens.osd.maxMessageWidth - messageIcon.width - message.spacing)
            elideText: true
            text: root.shownText
            font.pixelSize: Tokens.fontSize.sm
            font.weight: Tokens.font.semibold
            color: Theme.color.m3onSurface
        }
    }
}

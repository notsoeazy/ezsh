import QtQuick

import qs
import qs.config
import qs.themes
import qs.services
import qs.components

Item {
    id: root

    readonly property int maxMessageWidth: 480
    readonly property bool contentChangePending: OsdService.showsLevel !== root.displayedIsLevel || (!OsdService.showsLevel && (OsdService.messageText !== root.displayedText || OsdService.icon !== root.displayedIcon))

    property bool displayedIsLevel: false
    property string displayedText: ""
    property string displayedIcon: ""
    property real contentOpacity: 1
    property real levelValue: 0
    property string levelIcon: ""

    implicitWidth: root.displayedIsLevel ? slider.width : Math.min(root.maxMessageWidth, messageRow.implicitWidth)
    implicitHeight: root.displayedIsLevel ? slider.height : messageRow.height

    Behavior on implicitWidth {
        enabled: root.visible

        Anim {
            duration: Tokens.animDuration.spatialFast
            easing.type: Easing.OutBack
        }
    }

    Behavior on implicitHeight {
        enabled: root.visible

        Anim {
            duration: Tokens.animDuration.spatialFast
        }
    }

    Binding {
        target: root
        property: "levelValue"
        value: OsdService.level
        when: OsdService.showsLevel
        restoreMode: Binding.RestoreNone
    }

    Binding {
        target: root
        property: "levelIcon"
        value: OsdService.icon
        when: OsdService.showsLevel
        restoreMode: Binding.RestoreNone
    }

    function commitDisplayedContent() {
        root.displayedIsLevel = OsdService.showsLevel;
        root.displayedText = OsdService.messageText;
        root.displayedIcon = OsdService.icon;
    }

    Component.onCompleted: root.commitDisplayedContent()

    onContentChangePendingChanged: {
        if (!root.contentChangePending)
            return;
        if (!root.visible) {
            contentSwap.stop();
            root.contentOpacity = 1;
            Qt.callLater(root.commitDisplayedContent);
        } else if (!contentSwap.running) {
            contentSwap.restart();
        }
    }

    SequentialAnimation {
        id: contentSwap

        Anim {
            target: root
            property: "contentOpacity"
            to: 0
            duration: Tokens.animDuration.effectsFast
            easing.type: Easing.InCubic
        }
        ScriptAction {
            script: root.commitDisplayedContent()
        }
        Anim {
            target: root
            property: "contentOpacity"
            to: 1
            duration: Tokens.animDuration.effects
        }
    }

    Slider {
        id: slider

        x: (root.width - width) / 2
        y: (root.height - height) / 2
        value: root.levelValue
        icon: root.levelIcon
        interactive: OsdService.showing && root.displayedIsLevel
        opacity: root.displayedIsLevel ? root.contentOpacity : 0
        visible: opacity > 0

        onValueRequested: value => OsdService.setLevel(value)
        onStepRequested: direction => OsdService.stepLevel(direction)
        onPressedChanged: OsdService.setSliderPressed(slider.pressed)
    }

    Row {
        id: messageRow

        x: (root.width - width) / 2
        y: (root.height - height) / 2
        spacing: Tokens.spacing.xs
        leftPadding: Tokens.spacing.sm
        rightPadding: Tokens.spacing.sm + Tokens.spacing.xs
        opacity: root.displayedIsLevel ? 0 : root.contentOpacity
        visible: opacity > 0

        StyledIcon {
            id: messageIcon

            anchors.verticalCenter: parent.verticalCenter
            iconSize: Tokens.icon.md
            text: root.displayedIcon
        }

        StyledText {
            id: messageText

            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.maxMessageWidth - messageIcon.width - messageRow.spacing - messageRow.leftPadding - messageRow.rightPadding)
            elideText: true
            text: root.displayedText
            font.pixelSize: Tokens.fontSize.sm
            font.weight: Tokens.font.semibold
            color: Theme.color.m3onSurface
        }
    }
}

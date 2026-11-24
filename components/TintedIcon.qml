import QtQuick
import QtQuick.Effects
import Quickshell.Widgets

import qs
import qs.themes

Item {
    id: root

    property string source: ""
    property int size: Tokens.icon.md
    property color tint: Theme.color.m3onSurface
    property string fallback: "apps"

    readonly property int status: image.status
    readonly property bool loaded: root.source !== "" && image.status === Image.Ready

    implicitWidth: root.size
    implicitHeight: root.size

    IconImage {
        id: image

        anchors.fill: parent
        implicitSize: root.size
        source: root.source
        visible: false
    }

    MultiEffect {
        anchors.fill: image
        source: image
        visible: root.loaded
        colorization: 1
        colorizationColor: root.tint
    }

    StyledIcon {
        anchors.centerIn: parent
        visible: !root.loaded && root.fallback !== ""
        text: root.fallback
        iconSize: root.size
        fillAmount: 1
        color: Theme.color.m3onSurfaceVariant
    }
}

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

import qs
import qs.themes

// The distro's LOGO= icon from /etc/os-release, tinted to the theme.
Item {
    id: root

    readonly property string logoIconName: osRelease.text().match(/^LOGO=["']?([^"'\n]*)/m)?.[1] ?? ""
    readonly property bool available: root.logoIconName !== "" && logo.status !== Image.Error

    signal clicked()

    visible: root.available
    implicitWidth: root.available ? Tokens.icon.md : 0
    implicitHeight: Tokens.icon.md

    FileView {
        id: osRelease

        path: "/etc/os-release"
        blockLoading: true
    }

    Image {
        id: logo

        anchors.fill: parent
        source: root.logoIconName ? Quickshell.iconPath(root.logoIconName, true) : ""
        sourceSize: Qt.size(Tokens.icon.md * Screen.devicePixelRatio, Tokens.icon.md * Screen.devicePixelRatio)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: logo
        source: logo
        colorization: 1
        colorizationColor: Theme.color.m3onSurface
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

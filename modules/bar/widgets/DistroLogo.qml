import QtQuick
import Quickshell
import Quickshell.Io

import qs
import qs.components

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

    TintedIcon {
        id: logo

        anchors.fill: parent
        size: Tokens.icon.md
        source: root.logoIconName ? Quickshell.iconPath(root.logoIconName, true) : ""
        fallback: ""
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

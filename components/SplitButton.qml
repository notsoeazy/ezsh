import QtQuick

import qs

Item {
    id: root

    property string icon: ""
    property string text: ""
    property bool menuOpen: false
    property real buttonHeight: lead.defaultHeight

    readonly property alias chevron: trail
    readonly property int chevronWidth: 48
    readonly property int joinGap: 2

    signal clicked()
    signal menuRequested()

    implicitWidth: lead.implicitWidth + root.joinGap + root.chevronWidth
    implicitHeight: root.buttonHeight

    Button {
        id: lead

        width: root.width - root.chevronWidth - root.joinGap
        height: root.height
        icon: root.icon
        text: root.text
        endRadius: Tokens.radius.sm
        onClicked: root.clicked()
    }

    Button {
        id: trail

        x: root.width - width
        width: root.chevronWidth
        height: root.height
        icon: "expand_more"
        iconRotation: root.menuOpen ? 180 : 0
        startRadius: root.menuOpen ? height / 2 : Tokens.radius.sm
        Accessible.name: root.text + " options"
        onClicked: root.menuRequested()
    }
}

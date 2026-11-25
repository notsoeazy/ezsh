pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property Fonts font: Fonts {}
    readonly property FontSizes fontSize: FontSizes {}
    readonly property Icon icon: Icon {}
    readonly property Spacing spacing: Spacing {}
    readonly property Radius radius: Radius {}
    readonly property Stroke stroke: Stroke {}
    readonly property AnimationDurations animDuration: AnimationDurations {}
    readonly property Opacity opacity: Opacity {}
    readonly property Bar bar: Bar {}
    readonly property Launcher launcher: Launcher {}
    readonly property ControlPanel controlPanel: ControlPanel {}

    component Fonts: QtObject {
        readonly property string family: "Inter"
        readonly property string nerd: "JetBrainsMono Nerd Font"
        readonly property int thin: 300
        readonly property int light: 400
        readonly property int regular: 500
        readonly property int semibold: 600
        readonly property int bold: 700
    }

    component FontSizes: QtObject {
        readonly property int xs: 12
        readonly property int sm: 14
        readonly property int md: 16
        readonly property int lg: 18
        readonly property int xl: 22
        readonly property int xxl: 26
    }

    component Icon: QtObject {
        readonly property int xs: 14
        readonly property int sm: 16
        readonly property int md: 20
        readonly property int lg: 24
        readonly property int xl: 32

        readonly property int gradeDark: -25
        readonly property int gradeLight: 0
        readonly property int weight: 400
    }

    component Spacing: QtObject {
        readonly property int xxs: 4
        readonly property int xs: 8
        readonly property int sm: 10
        readonly property int md: 16
        readonly property int lg: 18
        readonly property int xl: 20
        readonly property int xxl: 24
        readonly property int xxxl: 32
    }

    component Radius: QtObject {
        readonly property int sm: 4
        readonly property int md: 8
        readonly property int lg: 10
        readonly property int xl: 16
        readonly property int full: 9999
    }

    // Outline and focus-ring widths.
    component Stroke: QtObject {
        readonly property int thin: 1
        readonly property int thick: 2
    }

    component AnimationDurations: QtObject {
        readonly property int spatialFast: 250
        readonly property int spatial: 350
        readonly property int spatialSlow: 500

        readonly property int effectsFast: 150
        readonly property int effects: 200
        readonly property int effectsSlow: 300
    }

    component Opacity: QtObject {
        readonly property real hover: 0.15
        readonly property real focus: 0.10
        readonly property real pressed: 0.2
        readonly property real disabledContent: 0.38
        readonly property real disabledContainer: 0.12
        readonly property real placeholder: 0.12
    }

    component Launcher: QtObject {
        readonly property int rowHeight: 50
    }

    component ControlPanel: QtObject {
        readonly property int controlHeight: 44
    }

    component Bar: QtObject {
        readonly property int iconButtonSize: 26
        readonly property int workspaceDotSize: 9
        readonly property int workspaceSpacing: 6
        readonly property int horizontalPadding: 16
        readonly property int verticalPadding: 8
        readonly property int centerGap: 40
        readonly property int collapsedHeight: iconButtonSize + verticalPadding * 2 // fix this in future to be responsive of content
        readonly property int expandedHeight: 88 // fix this in future to be responsive to content
        // Where in the expand motion (0..1) the secondary rows and the dashboard start fading in.
        readonly property real secondaryRevealStart: 0.4
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.utils

// Material 3 color roles. They come from a selector's preview while one is shown, else from the
// applied theme ($XDG_STATE_HOME/ezsh/colors.json, written by scripts/theme.py). The values here
// are the built-in Default dark scheme, used until a theme is applied or if the file can't be read.
Singleton {
    id: root

    // {id, name, mode, colors} from theme.py; preview wins while it is set (null for none).
    readonly property var preview: themeState.preview
    readonly property var applied: themeState.applied
    readonly property string colorsPath: `${FilePaths.state}/colors.json`
    readonly property var shown: root.preview ?? root.applied
    readonly property bool dark: root.shown?.mode !== "light"
    readonly property Colors color: Colors {
        roles: root.shown?.colors ?? {}
    }

    function setPreview(result) {
        themeState.preview = result;
    }

    function setApplied(result) {
        themeState.applied = result;
    }

    function readColors() {
        const text = colorsFile.text();
        if (!text)
            return;
        try {
            const result = JSON.parse(text);
            if (result?.colors)
                root.setApplied(result);
        } catch (error) {
            console.warn("Theme: bad colors.json, keeping the current colors", error);
        }
    }

    // Read while Theme is created, before anything binds to its colors, so the shell doesn't start
    // in the Default colors and fade over (the loaded signal comes too late for that).
    Component.onCompleted: root.readColors()

    QtObject {
        id: themeState

        property var preview: null
        property var applied: null
    }

    FileView {
        id: colorsFile

        path: root.colorsPath
        watchChanges: true
        printErrors: false
        blockLoading: true

        onFileChanged: colorsFile.reload()
        onLoaded: root.readColors()
    }

    component Colors: QtObject {
        id: colors

        property var roles: ({})

        // Primary
        readonly property color m3primary: colors.pick("primary", "#AAC7FF")
        readonly property color m3surfaceTint: colors.pick("surfaceTint", "#AAC7FF")
        readonly property color m3onPrimary: colors.pick("onPrimary", "#0A305F")
        readonly property color m3primaryContainer: colors.pick("primaryContainer", "#284777")
        readonly property color m3onPrimaryContainer: colors.pick("onPrimaryContainer", "#D6E3FF")
        // Secondary
        readonly property color m3secondary: colors.pick("secondary", "#BEC6DC")
        readonly property color m3onSecondary: colors.pick("onSecondary", "#283141")
        readonly property color m3secondaryContainer: colors.pick("secondaryContainer", "#3E4759")
        readonly property color m3onSecondaryContainer: colors.pick("onSecondaryContainer", "#DAE2F9")
        // Tertiary
        readonly property color m3tertiary: colors.pick("tertiary", "#DDBCE0")
        readonly property color m3onTertiary: colors.pick("onTertiary", "#3F2844")
        readonly property color m3tertiaryContainer: colors.pick("tertiaryContainer", "#573E5C")
        readonly property color m3onTertiaryContainer: colors.pick("onTertiaryContainer", "#FAD8FD")
        // Error
        readonly property color m3error: colors.pick("error", "#FFB4AB")
        readonly property color m3onError: colors.pick("onError", "#690005")
        readonly property color m3errorContainer: colors.pick("errorContainer", "#93000A")
        readonly property color m3onErrorContainer: colors.pick("onErrorContainer", "#FFDAD6")
        // Background & Surface
        readonly property color m3background: colors.pick("background", "#000000")
        readonly property color m3onBackground: colors.pick("onBackground", "#FFFFFF")
        readonly property color m3surface: colors.pick("surface", "#111318")
        readonly property color m3onSurface: colors.pick("onSurface", "#E2E2E9")
        readonly property color m3surfaceVariant: colors.pick("surfaceVariant", "#44474E")
        readonly property color m3onSurfaceVariant: colors.pick("onSurfaceVariant", "#C4C6D0")
        // Outline
        readonly property color m3outline: colors.pick("outline", "#8E9099")
        readonly property color m3outlineVariant: colors.pick("outlineVariant", "#44474E")
        // Shadow & Scrim
        readonly property color m3shadow: colors.pick("shadow", "#000000")
        readonly property color m3scrim: colors.pick("scrim", "#000000")
        // Inverse Colors
        readonly property color m3inverseSurface: colors.pick("inverseSurface", "#E2E2E9")
        readonly property color m3inverseOnSurface: colors.pick("inverseOnSurface", "#2E3036")
        readonly property color m3inversePrimary: colors.pick("inversePrimary", "#415F91")
        // Primary Fixed
        readonly property color m3primaryFixed: colors.pick("primaryFixed", "#D6E3FF")
        readonly property color m3onPrimaryFixed: colors.pick("onPrimaryFixed", "#001B3E")
        readonly property color m3primaryFixedDim: colors.pick("primaryFixedDim", "#AAC7FF")
        readonly property color m3onPrimaryFixedVariant: colors.pick("onPrimaryFixedVariant", "#284777")
        // Secondary Fixed
        readonly property color m3secondaryFixed: colors.pick("secondaryFixed", "#DAE2F9")
        readonly property color m3onSecondaryFixed: colors.pick("onSecondaryFixed", "#131C2B")
        readonly property color m3secondaryFixedDim: colors.pick("secondaryFixedDim", "#BEC6DC")
        readonly property color m3onSecondaryFixedVariant: colors.pick("onSecondaryFixedVariant", "#3E4759")
        // Tertiary Fixed
        readonly property color m3tertiaryFixed: colors.pick("tertiaryFixed", "#FAD8FD")
        readonly property color m3onTertiaryFixed: colors.pick("onTertiaryFixed", "#28132E")
        readonly property color m3tertiaryFixedDim: colors.pick("tertiaryFixedDim", "#DDBCE0")
        readonly property color m3onTertiaryFixedVariant: colors.pick("onTertiaryFixedVariant", "#573E5C")
        // Surface Containers
        readonly property color m3surfaceDim: colors.pick("surfaceDim", "#111318")
        readonly property color m3surfaceBright: colors.pick("surfaceBright", "#37393E")
        readonly property color m3surfaceContainerLowest: colors.pick("surfaceContainerLowest", "#0C0E13")
        readonly property color m3surfaceContainerLow: colors.pick("surfaceContainerLow", "#191C20")
        readonly property color m3surfaceContainer: colors.pick("surfaceContainer", "#1D2024")
        readonly property color m3surfaceContainerHigh: colors.pick("surfaceContainerHigh", "#282A2F")
        readonly property color m3surfaceContainerHighest: colors.pick("surfaceContainerHighest", "#33353A")

        function pick(role, fallback) {
            return colors.roles[role] ?? fallback;
        }
    }
}

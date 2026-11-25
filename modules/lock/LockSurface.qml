import QtQuick
import Quickshell
import Quickshell.Wayland

import qs
import qs.config
import qs.themes
import qs.services
import qs.components

// Transparent at first: the bar's clock grows into the large clock while the wallpaper fades in, and plays back on unlock.
WlSessionLockSurface {
    id: root

    // The wallpaper has loaded (or there is none).
    property bool entered: false
    property real progress: (root.entered || LockService.instant) && !LockService.unlocking ? 1 : 0 // 0 = clock in the bar, 1 = locked layout.
    property real shakeProgress: 1 // 0..1 through the rejection shake.
    property bool inputRequested: false
    property real inputProgress: root.inputShown ? 1 : 0

    readonly property int clockSize: 112
    readonly property int fieldWidth: 320
    readonly property int shakeDistance: 12
    readonly property int shakeSwings: 3
    readonly property real scrimOpacity: 0.3
    readonly property int inputHideInterval: 10000
    readonly property real formBottomFraction: 0.1
    readonly property bool inputShown: root.contentReveal === 1 && !LockService.unlocking && (root.inputRequested || field.text !== "" || LockService.busy)
    readonly property size targetSize: Qt.size(Math.ceil(root.width * (root.screen?.devicePixelRatio ?? 1)), Math.ceil(root.height * (root.screen?.devicePixelRatio ?? 1)))
    // The collapsed bar's clock center (see bar/Bar.qml).
    // shortcut: assumes the clock is centered (Config.bar.symmetricSides), compute the bar's offset if asymmetric sides look off.
    readonly property real barClockY: Config.border.thickness + (Config.bar.floating ? Config.bar.floatingGap : 0) + Tokens.bar.collapsedHeight / 2
    readonly property real clockY: root.height / 2 - root.clockSize / 2
    readonly property real contentReveal: Math.max(0, root.progress * 2 - 1)

    color: "transparent"

    function checkEntered() {
        if (wallpaper.status !== Image.Loading)
            root.entered = true;
    }

    function requestInput() {
        root.inputRequested = true;
        inputHideTimer.restart();
    }

    function checkReleased() {
        if (LockService.unlocking && root.progress === 0)
            LockService.release();
    }

    Component.onCompleted: {
        WallpaperService.prepare(WallpaperService.current, root.targetSize);
        Qt.callLater(root.checkEntered);
    }
    onProgressChanged: {
        if (root.progress === 1)
            LockService.reportShown();
        root.checkReleased();
    }

    Behavior on progress {
        enabled: !LockService.instant

        Anim {
            duration: Tokens.animDuration.spatialSlow
        }
    }

    Behavior on inputProgress {
        Anim {}
    }

    Item {
        id: backdrop

        anchors.fill: parent
        opacity: root.progress
        visible: opacity > 0

        StyledRectangle {
            anchors.fill: parent
            color: Theme.color.m3background
        }

        Image {
            id: wallpaper

            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            autoTransform: true
            cache: false
            source: WallpaperService.source(WallpaperService.current, root.targetSize)
            sourceSize: root.targetSize

            onStatusChanged: root.checkEntered()
        }

        StyledRectangle {
            anchors.fill: parent
            color: Qt.alpha(Theme.color.m3background, root.scrimOpacity)
        }
    }

    StyledText {
        id: dateLabel

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.clockY - clock.height / 2 - dateLabel.height + (1 - root.contentReveal) * Tokens.spacing.md
        opacity: root.contentReveal
        visible: opacity > 0
        text: TimeService.longDate
        font.pixelSize: Tokens.fontSize.xl
        font.weight: Tokens.font.semibold
        color: Theme.color.m3onSurface
    }

    StyledText {
        id: clock

        readonly property real barScale: Tokens.fontSize.md / root.clockSize

        x: (root.width - clock.width) / 2
        y: root.barClockY + (root.clockY - root.barClockY) * root.progress - clock.height / 2
        scale: clock.barScale + (1 - clock.barScale) * root.progress
        renderType: Text.QtRendering
        text: TimeService.clockText
        animateFontSize: false
        font.pixelSize: root.clockSize
        font.weight: Tokens.font.semibold
        font.features: ({
            "tnum": 1
        })
        color: Theme.color.m3onSurface
    }

    Column {
        id: form

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height * (1 - root.formBottomFraction) - form.height + (1 - root.inputProgress) * Tokens.spacing.md
        spacing: Tokens.spacing.sm
        // Never invisible: the hidden field keeps the keyboard, so the first key goes into it.
        opacity: root.inputProgress

        SearchBar {
            id: field

            width: root.fieldWidth
            focus: true
            echoMode: TextInput.Password
            placeholder: "Enter password"
            icon: LockService.unlocking ? "lock_open" : LockService.busy ? "pending" : "lock"
            Accessible.name: "Password"

            transform: Translate {
                x: root.shakeDistance * Math.sin(root.shakeProgress * Math.PI * 2 * root.shakeSwings) * (1 - root.shakeProgress)
            }

            onTextChanged: inputHideTimer.restart()
            onAccepted: {
                if (field.text === "")
                    root.requestInput();
                else
                    LockService.authenticate(field.text);
            }
            onEscapePressed: {
                field.text = "";
                root.inputRequested = false;
                LockService.clearError();
            }
        }

        StyledText {
            width: root.fieldWidth
            horizontalAlignment: Text.AlignHCenter
            wrapText: true
            animateTextChange: true
            text: LockService.errorText
            font.pixelSize: Tokens.fontSize.sm
            font.weight: Tokens.font.semibold
            color: Theme.color.m3error
        }
    }

    // Above the form: a click shows the hidden field, then presses pass through.
    MouseArea {
        anchors.fill: parent

        onPressed: event => {
            const wasShown = root.inputShown;
            root.requestInput();
            event.accepted = !wasShown;
        }
    }

    Anim {
        id: shake

        target: root
        property: "shakeProgress"
        from: 0
        to: 1
        duration: Tokens.animDuration.spatialSlow
        easing.type: Easing.Linear
    }

    Timer {
        id: inputHideTimer

        interval: root.inputHideInterval
        onTriggered: {
            if (field.text !== "" || LockService.busy)
                return;
            root.inputRequested = false;
            LockService.clearError();
        }
    }

    Connections {
        target: LockService

        function onFailed() {
            field.text = "";
            root.requestInput();
            shake.restart();
        }

        function onUnlockingChanged() {
            root.checkReleased();
        }
    }
}

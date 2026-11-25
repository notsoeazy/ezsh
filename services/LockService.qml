pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

import qs.config

// The lock screen's state, PAM password checks (assets/pam/ezsh) and the idle timers (lock, screen off, suspend).
// Also locks on `loginctl lock-session` and before sleep.
Singleton {
    id: root

    property bool locked: false
    property bool unlocking: false
    // Sleep is held back until the lock layout is drawn.
    property bool shown: false
    property bool instant: false
    property string errorText: ""
    property string pendingPassword: ""
    property var attemptMessages: []

    readonly property bool busy: pam.active
    readonly property int monitorRestartInterval: 5000
    // Escaped like systemd's bus_label_escape ("3" -> "_33").
    readonly property string sessionPath: {
        const id = Quickshell.env("XDG_SESSION_ID") ?? "";
        let label = "";
        for (let i = 0; i < id.length; i++) {
            const c = id[i];
            label += /[A-Za-z]/.test(c) || (i > 0 && /[0-9]/.test(c)) ? c : "_" + c.charCodeAt(0).toString(16).padStart(2, "0");
        }
        return label ? "/org/freedesktop/login1/session/" + label : "";
    }

    signal failed()

    function lock(instant) {
        if (root.locked && !root.unlocking)
            return;
        ViewService.close();
        root.errorText = "";
        root.instant = instant === true;
        root.unlocking = false;
        root.locked = true;
    }

    function authenticate(password) {
        if (!root.locked || root.unlocking || pam.active || !password)
            return;
        root.pendingPassword = password;
        root.attemptMessages = [];
        if (!pam.start())
            root.fail("Could not start authentication");
    }

    function clearError() {
        root.errorText = "";
    }

    function reportShown() {
        if (root.locked && !root.unlocking)
            root.shown = true;
    }

    function release() {
        if (!root.unlocking)
            return;
        root.unlocking = false;
        root.shown = false;
        root.locked = false;
    }

    function fail(text) {
        root.pendingPassword = "";
        root.errorText = text;
        root.failed();
    }

    PamContext {
        id: pam

        configDirectory: Quickshell.shellDir + "/assets/pam"
        config: "ezsh"

        onPamMessage: {
            if (pam.responseRequired) {
                pam.respond(root.pendingPassword);
                root.pendingPassword = "";
            } else if (pam.messageIsError) {
                root.attemptMessages = root.attemptMessages.concat([pam.message]);
            }
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.pendingPassword = "";
                root.errorText = "";
                root.instant = false;
                root.unlocking = true;
            } else if (result === PamResult.MaxTries) {
                root.fail(root.attemptMessages.join(" ") || "Too many attempts");
            } else {
                root.fail(root.attemptMessages.join(" ") || "Incorrect password");
            }
        }

        onError: error => {
            console.warn("LockService: PAM error", PamError.toString(error));
            root.fail("Authentication failed");
        }
    }

    // logind's Unlock is ignored: only a password unlocks.
    Process {
        id: logindMonitor

        running: true
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1"]

        stdout: SplitParser {
            onRead: line => {
                if (root.sessionPath && line === root.sessionPath + ": org.freedesktop.login1.Session.Lock ()")
                    root.lock();
                else if (line === "/org/freedesktop/login1: org.freedesktop.login1.Manager.PrepareForSleep (true,)")
                    root.lock(true);
            }
        }

        onExited: code => {
            console.warn("LockService: gdbus monitor failed with code", code);
            monitorRestartTimer.start();
        }
    }

    Timer {
        id: monitorRestartTimer

        interval: root.monitorRestartInterval
        onTriggered: logindMonitor.running = true
    }

    // Delays sleep until the lock is drawn; cat exits when its stdin closes on stop.
    Process {
        running: !root.shown
        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=ezsh", "--why=Lock the screen before sleep", "cat"]
        stdinEnabled: true
    }

    IdleMonitor {
        id: lockMonitor

        enabled: Config.session.lockTimeout > 0 && !root.locked
        timeout: Config.session.lockTimeout
        respectInhibitors: true

        onIsIdleChanged: {
            if (lockMonitor.isIdle)
                root.lock();
        }
    }

    IdleMonitor {
        id: screenOffMonitor

        enabled: Config.session.screenOffTimeout > 0 && (Config.session.screenOffWhilePlaying || !MediaService.playing)
        timeout: Config.session.screenOffTimeout
        respectInhibitors: true

        onIsIdleChanged: HyprlandService.setDpms(!screenOffMonitor.isIdle)
    }

    IdleMonitor {
        id: suspendMonitor

        // Music players don't inhibit idle; playback counts as activity.
        enabled: Config.session.suspendTimeout > 0 && !MediaService.playing
        timeout: Config.session.suspendTimeout
        respectInhibitors: true

        onIsIdleChanged: {
            if (suspendMonitor.isIdle)
                SessionService.suspend();
        }
    }

    // qs ipc call lock lock
    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }
    }
}

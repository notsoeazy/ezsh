pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.config

Singleton {
    id: root

    function lock() {
        LockService.lock();
    }

    function logout() {
        HyprlandService.exit();
    }

    function suspend() {
        root.run(Config.session.suspend);
    }

    function reboot() {
        root.run(Config.session.reboot);
    }

    function poweroff() {
        root.run(Config.session.poweroff);
    }

    function run(command) {
        if (runner.running || !Array.isArray(command) || command.length === 0)
            return;
        runner.command = command;
        runner.running = true;
    }

    Process {
        id: runner

        onExited: code => {
            if (code !== 0)
                console.warn("SessionService:", runner.command.join(" "), "failed with code", code);
        }
    }
}

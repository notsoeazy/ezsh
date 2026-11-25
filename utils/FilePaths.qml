pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string state: `${Quickshell.env("XDG_STATE_HOME") || `${root.home}/.local/state`}/ezsh`
    readonly property string runtime: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"

    // Expands a leading "~" and "$HOME" / "${HOME}", as written in Config.
    function absolutePath(path) {
        return path.replace(/^~(?=\/|$)/, root.home).replace(/\$\{?HOME\}?/g, root.home);
    }

    function toFileUrl(path) {
        return "file://" + path.split("/").map(encodeURIComponent).join("/");
    }
}

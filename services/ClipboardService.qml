pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../utils/fuzzysort.mjs" as Fuzzysort

Singleton {
    id: root

    property var entries: []

    readonly property var index: Fuzzysort.default.snapshot(root.entries, {
        key: "text"
    })

    function refresh() {
        lister.running = true;
    }

    function search(query) {
        if (!query)
            return root.entries;
        return Fuzzysort.default.go(query, root.index, {
            limit: 0,
            threshold: 0
        }).map(result => result.obj);
    }

    function copy(id) {
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", id]);
    }

    function copyText(text) {
        Quickshell.execDetached(["wl-copy", "--", text]);
    }

    Process {
        id: lister

        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(line => line.length > 0).map(line => {
                    const tab = line.indexOf("\t");
                    const preview = line.slice(tab + 1);
                    return {
                        id: line.slice(0, tab),
                        text: preview,
                        image: preview.startsWith("[[ binary data")
                    };
                });
            }
        }

        onExited: code => {
            if (code !== 0)
                console.warn("ClipboardService: cliphist list failed with code", code);
        }
    }
}

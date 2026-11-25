pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.config

import "../utils/fuzzysort.mjs" as Fuzzysort

Singleton {
    id: root

    readonly property var cache: ({
            index: null,
            firstEntries: [],
            firstNerdEntries: []
        })
    // Ms the index outlives the launcher, so reopening it soon doesn't rebuild the index.
    readonly property int indexTimeout: 30000

    function search(query) {
        if (root.cache.index === null)
            root.load();
        releaseTimer.stop();

        const nerdMatch = query.trim().match(/^nf(\s+|$)(.*)/i);
        const text = nerdMatch ? nerdMatch[2] : query.trim();
        if (!text)
            return nerdMatch ? root.cache.firstNerdEntries : root.cache.firstEntries;

        return Fuzzysort.default.go(text, root.cache.index, {
            limit: Config.launcher.maxSymbolResults,
            threshold: 0,
            scoreFn: r => {
                if (nerdMatch && !r.obj.nerd)
                    return 0;
                const score = Math.max(r[0]?.score ?? 0, (r[1]?.score ?? 0) * 0.6);
                return r.obj.nerd && !nerdMatch ? score * 0.5 : score;
            }
        }).map(result => result.obj);
    }

    function load() {
        const entries = [];
        for (const line of file.text().split("\n")) {
            if (!line)
                continue;
            const [glyph, title, group, words] = line.split("\t");
            entries.push({
                glyph: glyph,
                title: title,
                group: group,
                nerd: group.startsWith("Nerd Font"),
                words: words ?? ""
            });
        }
        root.cache.index = Fuzzysort.default.snapshot(entries, {
            keys: ["title", "words"]
        });
        root.cache.firstEntries = entries.slice(0, Config.launcher.maxSymbolResults);
        root.cache.firstNerdEntries = entries.filter(entry => entry.nerd).slice(0, Config.launcher.maxSymbolResults);
    }

    function scheduleRelease() {
        if (root.cache.index !== null)
            releaseTimer.restart();
    }

    function release() {
        root.cache.index = null;
        root.cache.firstEntries = [];
        root.cache.firstNerdEntries = [];
        gc();
    }

    Timer {
        id: releaseTimer

        interval: root.indexTimeout
        onTriggered: root.release()
    }

    FileView {
        id: file

        path: Quickshell.shellPath("assets/symbols.tsv")
        blockLoading: true
    }
}

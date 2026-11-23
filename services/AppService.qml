pragma Singleton

import QtQuick
import Quickshell

import "../utils/fuzzysort.mjs" as Fuzzysort

Singleton {
    id: root

    readonly property var applications: DesktopEntries.applications.values.filter(app => !app.noDisplay).sort((a, b) => (a.name || "").localeCompare(b.name || ""))

    readonly property var index: Fuzzysort.default.snapshot(root.applications.map(app => ({
                app: app,
                name: app.name || "",
                other: `${app.genericName || ""} ${app.comment || ""} ${(app.keywords || []).join(" ")}`
            })), {
        keys: ["name", "other"]
    })

    function search(query) {
        return Fuzzysort.default.go(query, root.index, {
            limit: 0,
            threshold: 0,
            // The name counts double the description and keywords.
            scoreFn: r => Math.max(r[0]?.score ?? 0, (r[1]?.score ?? 0) * 0.5)
        }).map(result => result.obj.app);
    }

    function launch(app) {
        app?.execute();
    }
}

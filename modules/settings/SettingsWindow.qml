import QtQuick
import QtQuick.Controls as Controls
import Quickshell

import qs
import qs.config
import qs.themes
import qs.services
import qs.components
import qs.modules.settings.widgets

// The settings window: a sidebar of pages with search over every setting, and the chosen page (or
// the search results) as cards of rows. Narrow windows show only the sidebar icons and move the
// search next to the back and forward buttons.
FloatingWindow {
    id: root

    // Opens on the page asked for, else the first.
    property string currentName: root.pages.some(page => page.name === SettingsService.page) ? SettingsService.page : root.pages[0].name
    // Visited page names, for back and forward.
    property var history: [root.currentName]
    property int historyIndex: 0

    readonly property int defaultWidth: 980
    readonly property int defaultHeight: 720
    readonly property int minWidth: 420
    readonly property int minHeight: 360
    // Below this width the sidebar shows only icons.
    readonly property int compactBelow: 760
    readonly property int sidebarWidth: 300
    // A compact NavItem (56) with half a margin on each side.
    readonly property int compactSidebarWidth: 80
    readonly property int contentMaxWidth: 760
    readonly property int margin: Tokens.spacing.xxl
    readonly property int toolbarHeight: 48
    readonly property int scrollBarWidth: 4

    readonly property list<SettingsPage> pages: [
        NetworkSettings {},
        BluetoothSettings {},
        DisplaySettings {},
        AudioSettings {},
        BarSettings {},
        ClockSettings {},
        AppearanceSettings {},
        LauncherSettings {},
        OsdSettings {},
        CaptureSettings {},
        SessionSettings {},
        AboutSettings {}
    ]
    readonly property bool compact: root.width < root.compactBelow
    readonly property SettingsPage currentPage: root.pages.find(page => page.name === root.currentName) ?? root.pages[0]
    readonly property var queryWords: searchBar.text.toLowerCase().split(/\s+/).filter(word => word !== "")
    readonly property bool searching: root.queryWords.length > 0
    // While searching: one section per page with its matching rows.
    readonly property var shownSections: root.searching ? root.searchResults() : root.currentPage.sections
    readonly property string pageKey: root.searching ? "" : root.currentName

    title: "ezsh Settings"
    implicitWidth: root.defaultWidth
    implicitHeight: root.defaultHeight
    minimumSize: Qt.size(root.minWidth, root.minHeight)
    color: Theme.color.m3background

    function navigate(name) {
        if (!name || !root.pages.some(page => page.name === name))
            return;
        searchBar.text = "";
        if (name === root.currentName)
            return;
        root.history = root.history.slice(0, root.historyIndex + 1).concat([name]);
        root.historyIndex = root.history.length - 1;
        root.show(name);
    }

    function goHistory(direction) {
        const index = root.historyIndex + direction;
        if (index < 0 || index >= root.history.length)
            return;
        searchBar.text = "";
        root.historyIndex = index;
        root.show(root.history[index]);
    }

    function show(name) {
        root.currentName = name;
        flickable.contentY = 0;
    }

    function markShown() {
        for (const page of root.pages)
            page.shown = !root.searching && page === root.currentPage;
    }

    function textOf(value) {
        return typeof value === "function" ? value() : value ?? "";
    }

    function searchResults() {
        const results = [];
        for (const page of root.pages) {
            const rows = [];
            for (const section of page.sections) {
                for (const row of section.rows) {
                    const haystack = [page.title, section.title, row.label, root.textOf(row.description)].join(" ").toLowerCase();
                    if (root.queryWords.every(word => haystack.includes(word)))
                        rows.push(row);
                }
            }
            if (rows.length > 0)
                results.push({ title: page.title, rows: rows });
        }
        return results;
    }

    // Pages scan for networks and devices only while shown, so tell them, and stop when the window goes.
    onCurrentPageChanged: root.markShown()
    onSearchingChanged: root.markShown()
    Component.onCompleted: root.markShown()
    Component.onDestruction: {
        for (const page of root.pages)
            page.shown = false;
    }
    // Closed from the compositor (a close keybind).
    onClosed: SettingsService.close()

    Behavior on color {
        CAnim {}
    }

    Shortcut {
        sequences: [StandardKey.Back]
        onActivated: root.goHistory(-1)
    }

    Shortcut {
        sequences: [StandardKey.Forward]
        onActivated: root.goHistory(1)
    }

    Shortcut {
        sequences: [StandardKey.Find]
        onActivated: {
            searchBar.forceActiveFocus();
            searchBar.selectAll();
        }
    }

    Item {
        id: sidebar

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }

        width: root.compact ? root.compactSidebarWidth : root.sidebarWidth

        Behavior on width {
            Anim {}
        }

        Flickable {
            id: navFlickable

            anchors {
                fill: parent
                topMargin: root.compact ? root.margin : root.margin + root.toolbarHeight + Tokens.spacing.md
                leftMargin: root.compact ? root.margin / 2 : root.margin
                rightMargin: root.compact ? root.margin / 2 : 0
            }

            contentHeight: navColumn.height + root.margin
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Column {
                id: navColumn

                width: navFlickable.width
                spacing: Tokens.spacing.xxs

                Repeater {
                    model: root.pages

                    NavItem {
                        id: navItem

                        required property SettingsPage modelData

                        width: navColumn.width
                        icon: navItem.modelData.icon
                        text: navItem.modelData.title
                        compact: root.compact
                        selected: !root.searching && navItem.modelData.name === root.currentName
                        onClicked: root.navigate(navItem.modelData.name)
                    }
                }
            }
        }
    }

    Item {
        id: content

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: sidebar.right
            right: parent.right
        }

        Row {
            id: toolbar

            x: column.x
            y: root.margin
            spacing: Tokens.spacing.xs

            Button {
                buttonHeight: root.toolbarHeight
                icon: "arrow_back"
                enabled: root.historyIndex > 0
                Accessible.name: "Back"
                onClicked: root.goHistory(-1)
            }

            Button {
                buttonHeight: root.toolbarHeight
                icon: "arrow_forward"
                enabled: root.historyIndex < root.history.length - 1
                Accessible.name: "Forward"
                onClicked: root.goHistory(1)
            }
        }

        Flickable {
            id: flickable

            anchors {
                fill: parent
                topMargin: toolbar.y + toolbar.height + Tokens.spacing.md
            }

            contentHeight: column.height + root.margin
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Controls.ScrollBar.vertical: Controls.ScrollBar {
                policy: Controls.ScrollBar.AsNeeded

                contentItem: StyledRectangle {
                    implicitWidth: root.scrollBarWidth
                    radius: Tokens.radius.full
                    color: Theme.color.m3outlineVariant
                }
            }

            Column {
                id: column

                x: Math.max(Tokens.spacing.md, (flickable.width - width) / 2)
                width: Math.min(root.contentMaxWidth, flickable.width - (root.compact ? root.margin : root.margin * 2))
                spacing: Tokens.spacing.lg

                // config.json doesn't parse: say so, since changes then last only until a restart.
                StyledRectangle {
                    width: parent.width
                    height: warning.implicitHeight + Tokens.spacing.md * 2
                    visible: !Config.writable
                    radius: Tokens.radius.xl
                    color: Theme.color.m3errorContainer

                    StyledText {
                        id: warning

                        x: Tokens.spacing.lg
                        y: Tokens.spacing.md
                        width: parent.width - Tokens.spacing.lg * 2
                        wrapText: true
                        animateFontSize: false
                        text: `${Config.path} has an error, so changes here apply but aren't saved. Fix the file and they will be.`
                        font.pixelSize: Tokens.fontSize.sm
                        color: Theme.color.m3onErrorContainer
                    }
                }

                PageHeader {
                    width: parent.width
                    visible: !root.searching
                    icon: root.currentPage.icon
                    title: root.currentPage.title
                    description: root.currentPage.description
                }

                // Rebuilt only when the page or search mode changes. Within a page, groups and rows are
                // kept by position, so a list that refreshes (devices, streams) doesn't destroy a field being typed in.
                Repeater {
                    model: [root.pageKey]

                    Column {
                        width: column.width
                        visible: root.shownSections.length > 0
                        spacing: column.spacing

                        Repeater {
                            model: CountModel {
                                size: root.shownSections.length
                            }

                            SettingsGroup {
                                id: group

                                required property int index

                                readonly property var section: root.shownSections[group.index] ?? ({ title: "", rows: [] })

                                width: column.width
                                title: group.section.title
                                rows: group.section.rows
                            }
                        }
                    }
                }

                StyledText {
                    width: parent.width
                    visible: root.searching && root.shownSections.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: Tokens.spacing.xxxl
                    animateFontSize: false
                    text: "No settings match"
                    font.pixelSize: Tokens.fontSize.md
                    color: Theme.color.m3onSurfaceVariant
                }
            }
        }
    }

    // One field for both layouts: atop the sidebar, or beside back / forward when compact.
    SearchBar {
        id: searchBar

        readonly property real compactX: content.x + toolbar.x + toolbar.width + Tokens.spacing.xs

        x: root.compact ? searchBar.compactX : root.margin
        y: root.margin
        width: root.compact ? Math.max(0, content.x + column.x + column.width - searchBar.compactX) : root.sidebarWidth - root.margin
        focus: true
        placeholder: "Search settings"
        onEscapePressed: {
            if (searchBar.text !== "")
                searchBar.text = "";
            else
                SettingsService.close();
        }
        onAccepted: {
            const first = root.shownSections[0];
            if (root.searching && first)
                root.navigate(root.pages.find(page => page.title === first.title)?.name ?? "");
        }
    }

    // Mouse back / forward buttons anywhere in the window; other buttons pass through.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton
        onClicked: event => root.goHistory(event.button === Qt.BackButton ? -1 : 1)
    }

    Connections {
        target: SettingsService

        function onPageChanged() {
            root.navigate(SettingsService.page);
        }
    }
}

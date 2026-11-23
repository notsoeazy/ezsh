import QtQuick

import qs
import qs.config
import qs.themes
import qs.services
import qs.components

Item {
    id: root

    readonly property int panelWidth: 500
    readonly property int contentPadding: 12
    readonly property int visibleRows: 6
    readonly property int emptyHeight: 96
    readonly property var pages: ({
            apps: appsPage,
            clipboard: clipboardPage,
            symbols: symbolsPage
        })
    readonly property bool commandMode: root.pageName === "apps" && search.text.startsWith(Config.launcher.commandPrefix)
    readonly property LauncherPage page: root.commandMode ? commandsPage : root.pages[root.pageName]
    readonly property string query: (root.commandMode ? search.text.slice(Config.launcher.commandPrefix.length) : search.text).trim()
    readonly property var results: root.page.results(root.query)
    readonly property int shownRows: Math.min(root.results.length, root.visibleRows)
    readonly property real listTargetHeight: root.shownRows > 0 ? root.shownRows * root.page.rowHeight : root.emptyHeight
    readonly property bool coversOsd: false

    property string pageName: "apps"
    property point pointerScene: Qt.point(-1, -1)

    signal closeRequested()
    signal navigateRequested(string view)

    implicitWidth: root.panelWidth
    implicitHeight: root.contentPadding * 2 + search.height + listArea.height + hints.height + Tokens.spacing.sm * 2

    function openPage(name) {
        if (!(name in root.pages)) {
            console.warn("LauncherView: unknown page", name);
            name = "apps";
        }
        root.pageName = name;
        search.text = "";
        root.page.prepare();
        ViewService.open("launcher", name === "apps" ? "" : name, ViewService.monitorName);
    }

    function showResults() {
        if (list.delegate !== root.page.row) {
            list.model = [];
            list.delegate = root.page.row;
        }
        list.model = root.results;
        list.currentIndex = root.results.length > 0 ? 0 : -1;
    }

    function close() {
        root.closeRequested();
    }

    function activate(index) {
        if (index >= 0 && index < root.results.length)
            root.page.activate(root.results[index], root);
    }

    function moveSelection(direction) {
        if (root.results.length > 0)
            list.currentIndex = Math.max(0, Math.min(root.results.length - 1, list.currentIndex + direction));
    }

    function pointerMoved(scene) {
        if (scene === root.pointerScene)
            return false;
        root.pointerScene = scene;
        return true;
    }

    Component.onDestruction: SymbolService.scheduleRelease()

    Component.onCompleted: {
        root.openPage(ViewService.page || "apps");
        root.showResults();
    }

    onResultsChanged: root.showResults()

    Connections {
        target: ViewService

        function onPageChanged() {
            const name = ViewService.page || "apps";
            if (ViewService.view === "launcher" && name !== root.pageName)
                root.openPage(name);
        }
    }

    AppsPage {
        id: appsPage
    }

    CommandsPage {
        id: commandsPage
    }

    ClipboardPage {
        id: clipboardPage
    }

    SymbolsPage {
        id: symbolsPage
    }

    SearchBar {
        id: search

        // Takes the keyboard when BarHost shows this view (its ViewSlot gets focus).
        focus: true
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: root.contentPadding
        }

        placeholder: root.page.placeholder
        icon: root.page.icon

        onAccepted: root.activate(list.currentIndex)
        onMoveRequested: direction => root.moveSelection(direction)
        // Esc always closes; Backspace on an empty search steps back from a page to apps.
        onEscapePressed: root.close()
        onBackspaceOnEmpty: {
            if (root.pageName !== "apps")
                root.openPage("apps");
        }
    }

    Item {
        id: listArea

        anchors {
            top: search.bottom
            left: parent.left
            right: parent.right
            topMargin: Tokens.spacing.sm
            leftMargin: root.contentPadding
            rightMargin: root.contentPadding
        }

        height: root.listTargetHeight

        Behavior on height {
            Anim {}
        }

        ListView {
            id: list

            anchors.fill: parent
            visible: count > 0
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: Tokens.animDuration.effects
            highlightMoveVelocity: -1
            highlightResizeDuration: 0

            highlight: StyledRectangle {
                radius: Tokens.radius.lg
                color: Qt.alpha(Theme.color.m3primary, Tokens.opacity.pressed)

                StyledText {
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.spacing.md
                    anchors.verticalCenter: parent.verticalCenter
                    animateFontSize: false
                    text: "Enter"
                    font.pixelSize: Tokens.fontSize.xs
                    color: Theme.color.m3onSurfaceVariant
                }
            }

            HoverHandler {
                onPointChanged: {
                    if (!root.pointerMoved(point.scenePosition))
                        return;
                    const index = list.indexAt(point.position.x + list.contentX, point.position.y + list.contentY);
                    if (index >= 0)
                        list.currentIndex = index;
                }
            }

            TapHandler {
                onTapped: eventPoint => root.activate(list.indexAt(eventPoint.position.x + list.contentX, eventPoint.position.y + list.contentY))
            }
        }

        Column {
            anchors.centerIn: parent
            visible: list.count === 0
            spacing: Tokens.spacing.xs

            StyledIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                iconSize: Tokens.icon.lg
                text: root.page.emptyIcon
                color: Theme.color.m3onSurfaceVariant
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.page.emptyText
                font.pixelSize: Tokens.fontSize.sm
                color: Theme.color.m3onSurfaceVariant
            }
        }
    }

    KeyHints {
        id: hints

        anchors {
            top: listArea.bottom
            left: parent.left
            right: parent.right
            topMargin: Tokens.spacing.sm
            leftMargin: root.contentPadding + Tokens.spacing.xs
            rightMargin: root.contentPadding + Tokens.spacing.xs
        }

        hints: [
            {
                key: "↑↓",
                label: "navigate"
            },
            {
                key: "↵",
                label: root.page.actionHint
            }
        ].concat(root.pageName === "apps" ? [
            {
                key: Config.launcher.commandPrefix,
                label: "commands"
            }
        ] : [
            {
                key: "⌫",
                label: "back"
            }
        ])
    }
}

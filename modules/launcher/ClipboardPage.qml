import QtQuick

import qs
import qs.themes
import qs.services
import qs.components

LauncherPage {
    id: root

    placeholder: "Search clipboard history"
    icon: "content_paste"
    emptyText: "Clipboard history is empty"
    emptyIcon: "content_paste_off"
    actionHint: "copy"
    rowHeight: 56 // two lines of text

    row: Component {
        Item {
            id: row

            required property var modelData // { id, text, image } from ClipboardService

            // cliphist previews an image as "[[ binary data 12 KiB png 800x600 ]]". To be updated once design is confirmed
            readonly property var imageInfo: row.modelData.image ? row.modelData.text.match(/binary data (.+?) (\w+) (\d+x\d+)/) : null

            width: ListView.view?.width ?? 0
            height: root.rowHeight

            Accessible.role: Accessible.ListItem
            Accessible.name: label.text

            StyledIcon {
                id: kindIcon

                x: Tokens.spacing.md
                anchors.verticalCenter: parent.verticalCenter
                iconSize: Tokens.icon.md
                text: row.modelData.image ? "image" : "notes"
                color: Theme.color.m3onSurfaceVariant
            }

            StyledText {
                id: label

                anchors {
                    left: kindIcon.right
                    right: parent.right
                    leftMargin: Tokens.spacing.md
                    rightMargin: Tokens.spacing.xxxl * 2
                    verticalCenter: parent.verticalCenter
                }

                wrapText: true
                elideText: true
                maximumLineCount: 2
                animateFontSize: false
                text: row.imageInfo ? `Image · ${row.imageInfo[2]} ${row.imageInfo[3]} · ${row.imageInfo[1]}` : row.modelData.text.replace(/\s+/g, " ").trim() || "(blank)"
                font.pixelSize: Tokens.fontSize.sm
                color: Theme.color.m3onSurface
            }
        }
    }

    function prepare() {
        ClipboardService.refresh();
    }

    function results(query) {
        return ClipboardService.search(query);
    }

    function activate(entry, launcher) {
        ClipboardService.copy(entry.id);
        launcher.close();
    }
}

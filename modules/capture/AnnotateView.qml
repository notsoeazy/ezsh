import QtQuick

import qs
import qs.config
import qs.themes
import qs.services
import qs.components
import qs.modules.capture.widgets

// The annotate stage. Opening slides the capture from the selection to the middle of the screen;
// closing slides it back over the selection (the owner keeps it loaded for the next open).
Item {
    id: root

    required property Item frozenScreen
    required property rect region
    required property real pixelRatio
    required property int toolbarMargin
    required property bool open

    property string tool: "pen"
    property color color: Config.capture.annotationColors[0]
    property bool chooserOpen: false
    property real openProgress: 0

    readonly property int margin: Tokens.spacing.xxxl
    readonly property var tools: [
        { name: "pen", label: "Draw", icon: "draw", key: Qt.Key_D, keyName: "D" },
        { name: "line", label: "Line", icon: "horizontal_rule", key: Qt.Key_L, keyName: "L" },
        { name: "arrow", label: "Arrow", icon: "arrow_outward", key: Qt.Key_A, keyName: "A" },
        { name: "rectangle", label: "Rectangle", icon: "rectangle", key: Qt.Key_R, keyName: "R" },
        { name: "ellipse", label: "Ellipse", icon: "circle", key: Qt.Key_E, keyName: "E" },
        { name: "text", label: "Text", icon: "title", key: Qt.Key_T, keyName: "T" },
        { name: "highlight", label: "Highlight", icon: "ink_highlighter", key: Qt.Key_H, keyName: "H" },
        { name: "blur", label: "Blur", icon: "blur_on", key: Qt.Key_B, keyName: "B" }
    ]
    readonly property real fitTop: root.margin
    readonly property real fitBottom: root.height - root.toolbarMargin - toolbar.height - Tokens.spacing.xl
    readonly property real fitScale: Math.min(1, (root.width - root.margin * 2) / root.region.width, (root.fitBottom - root.fitTop) / root.region.height)

    signal adjustRequested()

    visible: root.open || root.openProgress > 0

    function clearAnnotations() {
        annotations.clear();
    }

    function setTool(name) {
        annotations.commitText();
        root.tool = name;
    }

    function finish(saveToFile) {
        annotations.exportImage(result => CaptureService.deliverScreenshot(result, saveToFile));
    }

    function toggleChooser() {
        chooserLoader.active = true;
        const chooser = chooserLoader.item;
        const anchor = toolbar.chooserAnchor.mapToItem(root, toolbar.chooserAnchor.width / 2, 0);
        chooser.initialColor = root.color;
        chooser.x = Math.max(root.margin, Math.min(root.width - chooser.width - root.margin, anchor.x - chooser.width / 2));
        chooser.y = toolbar.y - chooser.height - Tokens.spacing.sm;
        root.chooserOpen = !root.chooserOpen;
    }

    // Bound after creation so the first open slides out of the selection too.
    Component.onCompleted: {
        root.openProgress = Qt.binding(() => root.open ? 1 : 0);
        root.forceActiveFocus();
    }
    onOpenChanged: {
        root.chooserOpen = false;
        if (root.open)
            root.forceActiveFocus();
    }

    Keys.onPressed: event => {
        const control = (event.modifiers & Qt.ControlModifier) !== 0;
        const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
        const tool = event.modifiers ? undefined : root.tools.find(t => t.key === event.key);
        if (event.key === Qt.Key_Escape && root.chooserOpen)
            root.chooserOpen = false;
        else if (event.key === Qt.Key_Escape)
            CaptureService.cancel();
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            root.finish(shift);
        else if (event.key === Qt.Key_Backspace)
            root.adjustRequested();
        else if (tool)
            root.setTool(tool.name);
        else if (control && event.key === Qt.Key_Z)
            annotations.undo();
        else if (control && event.key === Qt.Key_S)
            root.finish(true);
        else if (control && event.key === Qt.Key_C)
            root.finish(false);
        else
            return;
        event.accepted = true;
    }

    Behavior on openProgress {
        Anim {
            duration: Tokens.animDuration.spatialSlow
        }
    }

    AnnotationFrame {
        id: annotations

        x: root.region.x + ((root.width - root.region.width * root.fitScale) / 2 - root.region.x) * root.openProgress
        y: root.region.y + ((root.fitTop + root.fitBottom - root.region.height * root.fitScale) / 2 - root.region.y) * root.openProgress
        scale: 1 + (root.fitScale - 1) * root.openProgress
        transformOrigin: Item.TopLeft
        frozenScreen: root.frozenScreen
        region: root.region
        pixelRatio: root.pixelRatio
        tool: root.tool
        color: root.color
        drawingEnabled: root.openProgress === 1
    }

    Rectangle {
        x: annotations.x - border.width
        y: annotations.y - border.width
        width: annotations.width * annotations.scale + border.width * 2
        height: annotations.height * annotations.scale + border.width * 2
        color: "transparent"
        border.width: Tokens.stroke.thin
        border.color: Qt.alpha(Theme.color.m3outline, root.openProgress)
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.chooserOpen
        onPressed: root.chooserOpen = false
    }

    AnnotateToolbar {
        id: toolbar

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.toolbarMargin
        opacity: root.openProgress
        scale: 0.9 + 0.1 * root.openProgress
        tools: root.tools
        currentTool: root.tool
        currentColor: root.color
        canUndo: annotations.canUndo
        chooserOpen: root.chooserOpen
        onAdjustRequested: root.adjustRequested()
        onToolChosen: tool => root.setTool(tool)
        onColorChosen: color => root.color = color
        onChooserRequested: root.toggleChooser()
        onUndoRequested: annotations.undo()
        onCopyRequested: root.finish(false)
        onSaveRequested: root.finish(true)
    }

    // Created on first open, then kept so it can fade out.
    Loader {
        id: chooserLoader

        active: false

        sourceComponent: ColorChooser {
            id: chooser

            opacity: root.chooserOpen ? 1 : 0
            scale: 0.95 + 0.05 * chooser.opacity
            transformOrigin: Item.Bottom
            visible: chooser.opacity > 0
            onColorChosen: color => root.color = color

            Behavior on opacity {
                Anim {
                    duration: Tokens.animDuration.effects
                }
            }
        }
    }
}

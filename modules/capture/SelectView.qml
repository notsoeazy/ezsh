import QtQuick

import qs
import qs.services
import qs.components
import qs.modules.capture.widgets

// The select stage: what a click or Enter captures is the window under the pointer, else the whole
// screen, or a dragged region. It follows only pointer moves over the screen itself, so the toolbar
// never disturbs it. A locked selection is nudged with the arrows (Ctrl resizes, Shift steps by 10).
Item {
    id: root

    required property var screenInfo
    required property bool interactive
    required property int toolbarMargin

    property point pointerPosition: Qt.point(root.width / 2, root.height / 2)
    property point pressPosition: Qt.point(0, 0)
    property bool dragging: false
    property rect dragRect: Qt.rect(0, 0, 0, 0)
    property bool selectionLocked: false
    property rect lockedSelection: Qt.rect(0, 0, 0, 0)
    property bool movingByKeys: false

    readonly property string screenName: root.screenInfo.name
    readonly property int dragThreshold: 4
    readonly property int fastStep: 10
    readonly property rect wholeScreen: Qt.rect(0, 0, root.width, root.height)
    readonly property bool hasPointer: CaptureService.pointerScreen === root.screenName
    readonly property var windowRects: CaptureService.mode === "screen" ? [] : HyprlandService.windowsOn(root.screenName)
        .map(r => root.clipToScreen(Qt.rect(r.x - root.screenInfo.x, r.y - root.screenInfo.y, r.width, r.height)))
        .filter(r => r.width > 0 && r.height > 0)
    readonly property var selection: {
        if (root.dragging)
            return root.dragRect;
        if (root.selectionLocked)
            return root.lockedSelection;
        return root.hasPointer ? root.selectionAt(root.pointerPosition) : null;
    }

    signal confirmed(rect selection, bool fromPointer)

    function clipToScreen(r) {
        const x = Math.max(0, r.x);
        const y = Math.max(0, r.y);
        return Qt.rect(x, y, Math.min(root.width, r.x + r.width) - x, Math.min(root.height, r.y + r.height) - y);
    }

    function selectionAt(point) {
        return root.windowRects.find(r => point.x >= r.x && point.x < r.x + r.width && point.y >= r.y && point.y < r.y + r.height) ?? root.wholeScreen;
    }

    function lockTo(rect) {
        root.movingByKeys = false;
        root.lockedSelection = rect;
        root.selectionLocked = true;
    }

    function nudgeSelection(dx, dy, resize) {
        const r = root.selection;
        if (!r)
            return;
        root.movingByKeys = true;
        root.lockedSelection = resize
            ? Qt.rect(r.x, r.y, Math.max(1, Math.min(root.width - r.x, r.width + dx)), Math.max(1, Math.min(root.height - r.y, r.height + dy)))
            : Qt.rect(Math.max(0, Math.min(root.width - r.width, r.x + dx)), Math.max(0, Math.min(root.height - r.height, r.y + dy)), r.width, r.height);
        root.selectionLocked = true;
    }

    function confirm(rect, fromPointer) {
        if (rect && rect.width >= 1 && rect.height >= 1)
            root.confirmed(rect, fromPointer);
    }

    onHasPointerChanged: {
        if (!root.hasPointer)
            root.selectionLocked = false;
    }

    Keys.onPressed: event => {
        const resize = (event.modifiers & Qt.ControlModifier) !== 0;
        const step = event.modifiers & Qt.ShiftModifier ? root.fastStep : 1;
        const modes = ["region", "window", "screen"];
        switch (event.key) {
        case Qt.Key_Escape:
            CaptureService.cancel();
            break;
        case Qt.Key_Tab:
            CaptureService.setMode(modes[(modes.indexOf(CaptureService.mode) + 1) % modes.length]);
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            root.confirm(root.selection, false);
            break;
        case Qt.Key_Backspace:
            root.selectionLocked = false;
            break;
        case Qt.Key_Left:
            root.nudgeSelection(-step, 0, resize);
            break;
        case Qt.Key_Right:
            root.nudgeSelection(step, 0, resize);
            break;
        case Qt.Key_Up:
            root.nudgeSelection(0, -step, resize);
            break;
        case Qt.Key_Down:
            root.nudgeSelection(0, step, resize);
            break;
        default:
            return;
        }
        event.accepted = true;
    }

    Connections {
        target: CaptureService

        function onModeChanged() {
            root.selectionLocked = false;
        }
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.CrossCursor

        function followPointer() {
            root.pointerPosition = Qt.point(pointer.mouseX, pointer.mouseY);
            CaptureService.setPointerScreen(root.screenName);
        }

        onEntered: pointer.followPointer()
        onPressed: event => {
            if (event.button === Qt.RightButton)
                CaptureService.cancel();
            else
                root.pressPosition = Qt.point(event.x, event.y);
        }
        onPositionChanged: event => {
            if (!(pointer.pressedButtons & Qt.LeftButton)) {
                if (!root.selectionLocked)
                    pointer.followPointer();
                return;
            }
            if (CaptureService.mode !== "region")
                return;
            if (!root.dragging && Math.hypot(event.x - root.pressPosition.x, event.y - root.pressPosition.y) < root.dragThreshold)
                return;
            root.dragging = true;
            const x = Math.max(0, Math.min(event.x, root.width));
            const y = Math.max(0, Math.min(event.y, root.height));
            root.dragRect = Qt.rect(Math.min(x, root.pressPosition.x), Math.min(y, root.pressPosition.y), Math.abs(x - root.pressPosition.x), Math.abs(y - root.pressPosition.y));
        }
        onReleased: event => {
            if (event.button !== Qt.LeftButton)
                return;
            const rect = root.dragging ? root.dragRect : root.selectionAt(root.pressPosition);
            root.dragging = false;
            root.selectionLocked = false;
            root.pointerPosition = root.pressPosition;
            CaptureService.setPointerScreen(root.screenName);
            root.confirm(rect, true);
        }
    }

    SelectToolbar {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.toolbarMargin
        opacity: root.dragging || !root.interactive ? 0 : 1
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                duration: Tokens.animDuration.effects
            }
        }
    }
}

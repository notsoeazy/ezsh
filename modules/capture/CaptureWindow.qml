import QtQuick
import Quickshell
import Quickshell.Wayland

import qs
import qs.services
import qs.components
import qs.modules.capture.widgets

// The capture overlay on one screen: a frozen copy of it behind the select or annotate stage.
PanelWindow {
    id: root

    required property var modelData

    property string stage: "select" // "select" | "annotate"
    property bool hasCapture: false
    property rect capturedRect: Qt.rect(0, 0, 0, 0)
    property real contentOpacity: root.contentShown ? 1 : 0

    readonly property string screenName: root.modelData.name
    readonly property int toolbarMargin: Tokens.spacing.xxxl
    readonly property bool ownsCapture: CaptureService.ownerScreen === root.screenName
    readonly property bool yieldsToOtherScreen: CaptureService.ownerScreen !== "" && !root.ownsCapture
    readonly property bool contentShown: CaptureService.overlayShown && frozenView.hasContent && !root.yieldsToOtherScreen
    readonly property bool annotating: root.stage === "annotate"

    screen: root.modelData
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-capture"
    WlrLayershell.keyboardFocus: root.yieldsToOtherScreen ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
    mask: root.yieldsToOtherScreen ? emptyRegion : null

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    function handleConfirmed(rect, fromPointer) {
        if (CaptureService.kind === "record") {
            const wholeOutput = rect.width >= root.width && rect.height >= root.height;
            CaptureService.record(root.screenName, wholeOutput ? null : Qt.rect(rect.x + root.modelData.x, rect.y + root.modelData.y, rect.width, rect.height));
            return;
        }
        if (fromPointer)
            annotateLoader.item?.clearAnnotations();
        root.capturedRect = rect;
        root.hasCapture = true;
        root.stage = "annotate";
        CaptureService.setOwnerScreen(root.screenName);
    }

    function adjustCapture() {
        selectView.lockTo(root.capturedRect);
        root.stage = "select";
        selectView.forceActiveFocus();
    }

    function reportClosedOnceFaded() {
        if (root.contentOpacity === 0 && !CaptureService.overlayShown)
            CaptureService.overlayClosed();
    }

    onContentOpacityChanged: root.reportClosedOnceFaded()

    Behavior on contentOpacity {
        Anim {
            duration: Tokens.animDuration.effectsSlow
        }
    }

    Connections {
        target: CaptureService

        function onOverlayShownChanged() {
            root.reportClosedOnceFaded();
        }
    }

    Region {
        id: emptyRegion
    }

    Item {
        anchors.fill: parent
        opacity: root.contentOpacity

        ScreencopyView {
            id: frozenView

            anchors.fill: parent
            captureSource: root.modelData
            live: false
        }

        SelectionFrame {
            anchors.fill: parent
            selection: root.annotating ? Qt.rect(root.capturedRect.x + root.capturedRect.width / 2, root.capturedRect.y + root.capturedRect.height / 2, 0, 0) : selectView.selection
            dimOpacity: root.annotating ? 0.6 : 0.4
            moveInstantly: selectView.dragging || selectView.movingByKeys
            showOutline: !root.annotating
            showSize: (selectView.dragging || selectView.selectionLocked) && !root.annotating
            pixelRatio: root.modelData.devicePixelRatio
        }

        SelectView {
            id: selectView

            anchors.fill: parent
            focus: true
            screenInfo: root.modelData
            interactive: !root.annotating && !root.yieldsToOtherScreen
            toolbarMargin: root.toolbarMargin
            onConfirmed: (rect, fromPointer) => root.handleConfirmed(rect, fromPointer)
        }

        // Kept loaded after the first capture, so annotations survive adjusting the selection.
        Loader {
            id: annotateLoader

            anchors.fill: parent
            active: root.hasCapture

            sourceComponent: AnnotateView {
                frozenScreen: frozenView
                region: root.capturedRect
                pixelRatio: root.modelData.devicePixelRatio
                toolbarMargin: root.toolbarMargin
                open: root.annotating
                onAdjustRequested: root.adjustCapture()
            }
        }
    }
}

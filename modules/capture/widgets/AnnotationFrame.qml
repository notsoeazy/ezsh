import QtQuick
import QtQuick.Effects

import qs

// The captured region with its annotations, at the region's logical size. The image is the frozen
// screen cropped live, so nothing is grabbed until exportImage(). Blurs sit under the strokes.
Item {
    id: root

    required property Item frozenScreen
    required property rect region
    required property real pixelRatio
    required property string tool
    required property color color
    property bool drawingEnabled: true
    property var shapes: []
    property var shapeInProgress: null
    property var blurInProgress: null

    readonly property real strokeWidth: 4
    readonly property real arrowHeadLength: root.strokeWidth * 4
    readonly property int textSize: Tokens.fontSize.xxl
    readonly property real highlightOpacity: 0.35
    readonly property int blurRadius: 64
    readonly property bool canUndo: root.shapes.length > 0
    readonly property size pixelSize: Qt.size(Math.round(root.region.width * root.pixelRatio), Math.round(root.region.height * root.pixelRatio))

    width: root.region.width
    height: root.region.height

    function undo() {
        root.shapes = root.shapes.slice(0, -1);
    }

    function clear() {
        root.shapes = [];
    }

    function commitText() {
        if (textInput.visible && textInput.text.trim() !== "")
            root.shapes = root.shapes.concat([{ tool: "text", color: String(root.color), points: [Qt.point(textInput.x, textInput.y)], text: textInput.text }]);
        textInput.visible = false;
        textInput.text = "";
        root.forceActiveFocus();
    }

    function exportImage(callback) {
        root.commitText();
        root.grabToImage(callback, root.pixelSize);
    }

    function boundsOf(shape) {
        const a = shape.points[0];
        const b = shape.points[shape.points.length - 1];
        return Qt.rect(Math.min(a.x, b.x), Math.min(a.y, b.y), Math.abs(b.x - a.x), Math.abs(b.y - a.y));
    }

    function drawShape(ctx, shape) {
        const a = shape.points[0];
        const b = shape.points[shape.points.length - 1];
        const bounds = root.boundsOf(shape);
        ctx.strokeStyle = shape.color;
        ctx.fillStyle = shape.color;
        ctx.lineWidth = root.strokeWidth;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.beginPath();
        switch (shape.tool) {
        case "pen":
            ctx.moveTo(a.x, a.y);
            for (const p of shape.points)
                ctx.lineTo(p.x, p.y);
            ctx.stroke();
            break;
        case "line":
            ctx.moveTo(a.x, a.y);
            ctx.lineTo(b.x, b.y);
            ctx.stroke();
            break;
        case "arrow": {
            const angle = Math.atan2(b.y - a.y, b.x - a.x);
            ctx.moveTo(a.x, a.y);
            ctx.lineTo(b.x, b.y);
            for (const side of [-1, 1]) {
                ctx.moveTo(b.x, b.y);
                ctx.lineTo(b.x - root.arrowHeadLength * Math.cos(angle + side * Math.PI / 6), b.y - root.arrowHeadLength * Math.sin(angle + side * Math.PI / 6));
            }
            ctx.stroke();
            break;
        }
        case "rectangle":
            ctx.strokeRect(bounds.x, bounds.y, bounds.width, bounds.height);
            break;
        case "ellipse":
            ctx.ellipse(bounds.x, bounds.y, bounds.width, bounds.height);
            ctx.stroke();
            break;
        case "highlight":
            ctx.globalAlpha = root.highlightOpacity;
            ctx.fillRect(bounds.x, bounds.y, bounds.width, bounds.height);
            ctx.globalAlpha = 1;
            break;
        case "text":
            ctx.font = `${Tokens.font.semibold} ${root.textSize}px "${Tokens.font.family}"`;
            ctx.textBaseline = "top";
            ctx.fillText(shape.text, a.x, a.y);
            break;
        }
    }

    onShapesChanged: canvas.requestPaint()

    ShaderEffectSource {
        anchors.fill: parent
        sourceItem: root.frozenScreen
        sourceRect: root.region
        textureSize: root.pixelSize
    }

    Repeater {
        model: root.shapes.filter(shape => shape.tool === "blur").map(shape => root.boundsOf(shape)).concat(root.blurInProgress ? [root.blurInProgress] : [])

        Item {
            id: blurPatch

            required property rect modelData

            x: blurPatch.modelData.x
            y: blurPatch.modelData.y
            width: blurPatch.modelData.width
            height: blurPatch.modelData.height
            clip: true

            // Taken wider than the patch so the blur doesn't fade in from transparent at its edges.
            ShaderEffectSource {
                id: blurSource

                width: blurPatch.width + root.blurRadius * 2
                height: blurPatch.height + root.blurRadius * 2
                visible: false
                sourceItem: root.frozenScreen
                sourceRect: Qt.rect(root.region.x + blurPatch.x - root.blurRadius, root.region.y + blurPatch.y - root.blurRadius, blurSource.width, blurSource.height)
                textureSize: Qt.size(Math.ceil(blurSource.width * root.pixelRatio), Math.ceil(blurSource.height * root.pixelRatio))
            }

            MultiEffect {
                x: -root.blurRadius
                y: -root.blurRadius
                width: blurSource.width
                height: blurSource.height
                source: blurSource
                autoPaddingEnabled: false
                blurEnabled: true
                blur: 1
                blurMax: root.blurRadius
            }
        }
    }

    Canvas {
        id: canvas

        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            for (const shape of root.shapes)
                root.drawShape(ctx, shape);
            if (root.shapeInProgress)
                root.drawShape(ctx, root.shapeInProgress);
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.drawingEnabled
        cursorShape: root.tool === "text" ? Qt.IBeamCursor : Qt.CrossCursor

        onPressed: event => {
            if (root.tool === "text") {
                root.commitText();
                textInput.x = event.x;
                textInput.y = event.y;
                textInput.visible = true;
                textInput.forceActiveFocus();
                return;
            }
            root.shapeInProgress = { tool: root.tool, color: String(root.color), points: [Qt.point(event.x, event.y)] };
        }
        onPositionChanged: event => {
            const shape = root.shapeInProgress;
            if (!shape)
                return;
            const point = Qt.point(event.x, event.y);
            if (shape.tool === "pen")
                shape.points.push(point);
            else
                shape.points = [shape.points[0], point];
            if (shape.tool === "blur")
                root.blurInProgress = root.boundsOf(shape);
            canvas.requestPaint();
        }
        onReleased: {
            if (!root.shapeInProgress)
                return;
            if (root.shapeInProgress.points.length > 1)
                root.shapes = root.shapes.concat([root.shapeInProgress]);
            root.shapeInProgress = null;
            root.blurInProgress = null;
        }
    }

    TextInput {
        id: textInput

        visible: false
        color: root.color
        font.family: Tokens.font.family
        font.weight: Tokens.font.semibold
        font.pixelSize: root.textSize
        onAccepted: root.commitText()
        Keys.onEscapePressed: {
            textInput.text = "";
            root.commitText();
        }
    }
}

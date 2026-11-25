import QtQuick

import qs
import qs.themes
import qs.components

// Chooses any color from a saturation/brightness square, a hue strip or a typed hex value.
// Emits colorChosen live while dragging; set initialColor before showing it.
StyledRectangle {
    id: root

    property color initialColor: "red"
    property real hue: 0
    property real saturation: 1
    property real brightness: 1

    readonly property int areaSize: 180
    readonly property int stripHeight: 12
    readonly property int padding: Tokens.spacing.sm
    readonly property color chosenColor: Qt.hsva(root.hue, root.saturation, root.brightness, 1)

    signal colorChosen(color color)

    implicitWidth: column.implicitWidth + root.padding * 2
    implicitHeight: column.implicitHeight + root.padding * 2
    radius: Tokens.radius.xl
    color: Theme.color.m3surfaceContainer

    function choose(h, s, v) {
        root.hue = Math.max(0, Math.min(1, h));
        root.saturation = Math.max(0, Math.min(1, s));
        root.brightness = Math.max(0, Math.min(1, v));
        root.colorChosen(root.chosenColor);
    }

    // Grays report hue -1, so the hue strip keeps its place for them.
    onInitialColorChanged: {
        if (root.initialColor.hsvHue >= 0)
            root.hue = root.initialColor.hsvHue;
        root.saturation = root.initialColor.hsvSaturation;
        root.brightness = root.initialColor.hsvValue;
    }

    // Keeps clicks from drawing on the image underneath.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }

    Column {
        id: column

        x: root.padding
        y: root.padding
        spacing: Tokens.spacing.sm

        Rectangle {
            width: root.areaSize
            height: root.areaSize
            radius: Tokens.radius.md
            color: Qt.hsva(root.hue, 1, 1, 1)

            Rectangle {
                anchors.fill: parent
                radius: parent.radius

                gradient: Gradient {
                    orientation: Gradient.Horizontal

                    GradientStop { position: 0; color: "white" }
                    GradientStop { position: 1; color: Qt.alpha("white", 0) }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius

                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.alpha("black", 0) }
                    GradientStop { position: 1; color: "black" }
                }
            }

            Knob {
                x: root.saturation * parent.width - width / 2
                y: (1 - root.brightness) * parent.height - height / 2
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.CrossCursor
                onPressed: event => root.choose(root.hue, event.x / width, 1 - event.y / height)
                onPositionChanged: event => root.choose(root.hue, event.x / width, 1 - event.y / height)
            }
        }

        Rectangle {
            width: root.areaSize
            height: root.stripHeight
            radius: Tokens.radius.full

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop { position: 0 / 6; color: "#ff0000" }
                GradientStop { position: 1 / 6; color: "#ffff00" }
                GradientStop { position: 2 / 6; color: "#00ff00" }
                GradientStop { position: 3 / 6; color: "#00ffff" }
                GradientStop { position: 4 / 6; color: "#0000ff" }
                GradientStop { position: 5 / 6; color: "#ff00ff" }
                GradientStop { position: 6 / 6; color: "#ff0000" }
            }

            Knob {
                x: root.hue * parent.width - width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.hsva(root.hue, 1, 1, 1)
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -Tokens.spacing.xxs
                cursorShape: Qt.PointingHandCursor
                onPressed: event => root.choose(event.x / width, root.saturation, root.brightness)
                onPositionChanged: event => root.choose(event.x / width, root.saturation, root.brightness)
            }
        }

        Row {
            spacing: Tokens.spacing.xs

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Tokens.icon.md
                height: Tokens.icon.md
                radius: Tokens.radius.full
                color: root.chosenColor
                border.width: Tokens.stroke.thin
                border.color: Theme.color.m3outlineVariant
            }

            TextInput {
                id: hexInput

                anchors.verticalCenter: parent.verticalCenter
                width: root.areaSize - Tokens.icon.md - Tokens.spacing.xs
                text: root.chosenColor.toString().toUpperCase()
                color: Theme.color.m3onSurface
                selectionColor: Theme.color.m3primary
                selectedTextColor: Theme.color.m3onPrimary
                font.family: Tokens.font.family
                font.pixelSize: Tokens.fontSize.sm
                font.features: { "tnum": 1 }
                maximumLength: 7
                selectByMouse: true
                validator: RegularExpressionValidator {
                    regularExpression: /#?[0-9a-fA-F]{0,6}/
                }
                onAccepted: {
                    const hex = hexInput.text.replace("#", "");
                    if (hex.length === 6) {
                        const c = Qt.color("#" + hex);
                        root.choose(c.hsvHue >= 0 ? c.hsvHue : root.hue, c.hsvSaturation, c.hsvValue);
                    }
                    hexInput.text = Qt.binding(() => root.chosenColor.toString().toUpperCase());
                }
            }
        }
    }

    component Knob: Rectangle {
        width: Tokens.icon.xs
        height: Tokens.icon.xs
        radius: width / 2
        color: "transparent"
        border.width: Tokens.stroke.thick
        border.color: "white"
    }
}

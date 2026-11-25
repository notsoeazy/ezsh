import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

import qs
import qs.config
import qs.themes
import qs.services
import qs.components

Scope {
    id: root

    Variants {
        // No windows at all when disabled, so nothing is decoded for another wallpaper program.
        model: Config.wallpaper.enabled ? Quickshell.screens : []

        PanelWindow {
            id: window

            required property var modelData

            property bool frontIsA: true
            property real revealProgress: 0

            readonly property size targetSize: Qt.size(Math.ceil(window.width * window.modelData.devicePixelRatio), Math.ceil(window.height * window.modelData.devicePixelRatio))
            readonly property string desiredPath: WallpaperService.showing
            readonly property Image front: window.frontIsA ? layerA : layerB
            readonly property Image back: window.frontIsA ? layerB : layerA
            readonly property real revealRadius: Math.hypot(window.width / 2, window.height) + 2

            screen: window.modelData
            color: Theme.color.m3background
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "quickshell-wallpaper"
            mask: Region {}

            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }

            function requestImage() {
                if (revealAnimation.running || window.width <= 0)
                    return;
                if (window.front.path === window.desiredPath && window.front.status !== Image.Error) {
                    window.back.path = "";
                    return;
                }
                WallpaperService.prepare(window.desiredPath, window.targetSize);
                window.back.path = window.desiredPath;
                window.startReveal(window.back);
            }

            function startReveal(layer) {
                if (revealAnimation.running || layer !== window.back || layer.path !== window.desiredPath || layer.status !== Image.Ready)
                    return;
                revealAnimation.restart();
            }

            function layerStatusChanged(layer) {
                if (layer.status === Image.Ready)
                    window.startReveal(layer);
                else if (layer.status === Image.Error)
                    console.warn("Background: could not load", layer.path);
            }

            onDesiredPathChanged: loadDelay.restart()
            onTargetSizeChanged: {
                WallpaperService.prepare(window.front.path, window.targetSize);
                loadDelay.restart();
            }

            Timer {
                id: loadDelay

                interval: Config.wallpaper.previewDelay
                onTriggered: window.requestImage()
            }

            WallpaperLayer {
                id: layerA

                targetSize: window.targetSize
                visible: window.frontIsA
                onStatusChanged: window.layerStatusChanged(layerA)
            }

            WallpaperLayer {
                id: layerB

                targetSize: window.targetSize
                visible: !window.frontIsA
                onStatusChanged: window.layerStatusChanged(layerB)
            }

            Loader {
                anchors.fill: parent
                active: revealAnimation.running

                sourceComponent: Item {
                    MultiEffect {
                        anchors.fill: parent
                        source: window.back
                        maskEnabled: true
                        maskSource: revealMask
                    }

                    Item {
                        id: revealMask

                        anchors.fill: parent
                        visible: false
                        layer.enabled: true

                        Rectangle {
                            readonly property real currentRadius: window.revealRadius * Math.max(0, Math.min(1, window.revealProgress))

                            x: window.width / 2 - currentRadius
                            y: -currentRadius
                            width: currentRadius * 2
                            height: currentRadius * 2
                            radius: currentRadius
                        }
                    }
                }
            }

            Anim {
                id: revealAnimation

                target: window
                property: "revealProgress"
                from: 0
                to: 1
                duration: Tokens.animDuration.spatialSlow

                onFinished: {
                    window.frontIsA = !window.frontIsA;
                    window.back.path = "";
                    window.requestImage();
                }
            }

            component WallpaperLayer: Image {
                id: picture

                property string path: ""
                property size targetSize
                readonly property var pictureSize: WallpaperService.sizes[picture.path]

                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                autoTransform: true
                cache: false
                source: WallpaperService.source(picture.path, picture.targetSize)
                sourceSize: {
                    const d = picture.pictureSize;
                    if (!d || d[0] <= 0 || d[1] <= 0)
                        return Qt.size(-1, -1);
                    const scale = Math.min(1, Math.max(picture.targetSize.width / d[0], picture.targetSize.height / d[1]));
                    return Qt.size(Math.ceil(d[0] * scale), Math.ceil(d[1] * scale));
                }
            }
        }
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property bool available: root.player !== null
    readonly property bool playing: root.player?.isPlaying ?? false
    readonly property string title: root.player?.trackTitle ?? ""
    readonly property string artist: root.player?.trackArtist ?? ""
    readonly property string artUrl: root.player?.trackArtUrl ?? ""
    readonly property string playerName: root.player?.identity ?? ""
    readonly property real position: root.player?.position ?? 0
    readonly property real length: root.player?.length ?? 0
    readonly property bool hasProgress: (root.player?.positionSupported ?? false) && (root.player?.lengthSupported ?? false)
        && root.length > 0 && root.position <= root.length + 1
    readonly property bool canSeek: root.hasProgress && (root.player?.canSeek ?? false)
    readonly property bool canGoNext: root.player?.canGoNext ?? false
    readonly property bool canGoPrevious: root.player?.canGoPrevious ?? false
    readonly property bool canTogglePlaying: root.player?.canTogglePlaying ?? false

    function refreshPosition() {
        root.player?.positionChanged();
    }

    function seek(seconds) {
        if (root.canSeek && isFinite(seconds))
            root.player.position = Math.max(0, Math.min(root.length, seconds));
    }

    function togglePlaying() {
        if (root.canTogglePlaying)
            root.player.togglePlaying();
    }

    function next() {
        if (root.canGoNext)
            root.player.next();
    }

    function previous() {
        if (root.canGoPrevious)
            root.player.previous();
    }

    IpcHandler {
        target: "media"

        function playPause(): void {
            root.togglePlaying();
        }

        function next(): void {
            root.next();
        }

        function previous(): void {
            root.previous();
        }
    }

    GlobalShortcut {
        appid: "ezsh"
        name: "mediaPlayPause"
        description: "Play or pause media"
        onPressed: root.togglePlaying()
    }

    GlobalShortcut {
        appid: "ezsh"
        name: "mediaNext"
        description: "Next track"
        onPressed: root.next()
    }

    GlobalShortcut {
        appid: "ezsh"
        name: "mediaPrevious"
        description: "Previous track"
        onPressed: root.previous()
    }
}

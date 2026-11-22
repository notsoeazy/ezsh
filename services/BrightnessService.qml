pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import qs.config

// Screen and keyboard backlight. Each is unavailable (device "") when the machine has none.
Singleton {
    id: root

    readonly property BacklightDevice screen: BacklightDevice {
        minimum: 1
        stepSize: Config.services.brightnessStep / 100
    }

    // Keyboards have a few levels (often 0..2); a percent step would round back to the same one.
    readonly property BacklightDevice keyboard: BacklightDevice {
        poll: true
        stepSize: 1 / maximum
    }

    readonly property string screenIcon: root.screen.value < 0.34 ? "brightness_low"
        : root.screen.value < 0.67 ? "brightness_medium" : "brightness_high"

    readonly property string keyboardIcon: root.keyboard.value <= 0 ? "backlight_high_off"
        : root.keyboard.value < 0.5 ? "backlight_low" : "backlight_high"

    // qs ipc call brightness increase|decrease
    IpcHandler {
        target: "brightness"

        function increase(): void {
            root.screen.step(1);
        }

        function decrease(): void {
            root.screen.step(-1);
        }
    }

    // Hyprland: bind = ..., global, ezsh:brightnessUp
    GlobalShortcut {
        appid: "ezsh"
        name: "brightnessUp"
        description: "Raise screen brightness"
        onPressed: root.screen.step(1)
    }

    GlobalShortcut {
        appid: "ezsh"
        name: "brightnessDown"
        description: "Lower screen brightness"
        onPressed: root.screen.step(-1)
    }

    // "name,class,current,percent,max" per device.
    Process {
        running: true
        command: ["brightnessctl", "--list", "--machine-readable"]

        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const [name, cls, , , max] = line.split(",");
                    if (cls === "backlight" && !root.screen.available)
                        root.screen.attach(name, cls, Number(max));
                    else if (cls === "leds" && name.endsWith("kbd_backlight") && !root.keyboard.available)
                        root.keyboard.attach(name, cls, Number(max));
                }
            }
        }
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import qs.config

// Screen and keyboard backlight. Each is unavailable (deviceName "") when the machine has none.
Singleton {
    id: root

    readonly property BacklightDevice screenBacklight: BacklightDevice {
        minRaw: 1
        stepFraction: Config.services.brightnessStepPercent / 100
    }

    // Keyboards have a few levels (often 0..2); a percent step would round back to the same one.
    readonly property BacklightDevice keyboardBacklight: BacklightDevice {
        pollForChanges: true
        stepFraction: 1 / maxRaw
    }

    readonly property string screenIcon: root.screenBacklight.level < 0.34 ? "brightness_low"
        : root.screenBacklight.level < 0.67 ? "brightness_medium" : "brightness_high"

    readonly property string keyboardIcon: root.keyboardBacklight.level <= 0 ? "backlight_high_off"
        : root.keyboardBacklight.level < 0.5 ? "backlight_low" : "backlight_high"

    // qs ipc call brightness increase|decrease
    IpcHandler {
        target: "brightness"

        function increase(): void {
            root.screenBacklight.stepLevel(1);
        }

        function decrease(): void {
            root.screenBacklight.stepLevel(-1);
        }

        function keyboardIncrease(): void {
            root.keyboardBacklight.stepLevel(1);
        }

        function keyboardDecrease(): void {
            root.keyboardBacklight.stepLevel(-1);
        }
    }

    // Hyprland: bind = ..., global, ezsh:brightnessUp
    GlobalShortcut {
        appid: "ezsh"
        name: "brightnessUp"
        description: "Raise screen brightness"
        onPressed: root.screenBacklight.stepLevel(1)
    }

    GlobalShortcut {
        appid: "ezsh"
        name: "brightnessDown"
        description: "Lower screen brightness"
        onPressed: root.screenBacklight.stepLevel(-1)
    }

    GlobalShortcut {
        appid: "ezsh"
        name: "keyboardBrightnessUp"
        description: "Raise keyboard backlight"
        onPressed: root.keyboardBacklight.stepLevel(1)
    }

    GlobalShortcut {
        appid: "ezsh"
        name: "keyboardBrightnessDown"
        description: "Lower keyboard backlight"
        onPressed: root.keyboardBacklight.stepLevel(-1)
    }

    // "name,class,current,percent,max" per device.
    Process {
        running: true
        command: ["brightnessctl", "--list", "--machine-readable"]

        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const [name, deviceClass, , , maxRaw] = line.split(",");
                    if (deviceClass === "backlight" && !root.screenBacklight.available)
                        root.screenBacklight.useDevice(name, deviceClass, Number(maxRaw));
                    else if (deviceClass === "leds" && name.endsWith("kbd_backlight") && !root.keyboardBacklight.available)
                        root.keyboardBacklight.useDevice(name, deviceClass, Number(maxRaw));
                }
            }
        }
    }
}

import QtQuick
import Quickshell

import qs.services

SettingsPage {
    id: root

    readonly property var screenBacklight: BrightnessService.screenBacklight
    readonly property var keyboardBacklight: BrightnessService.keyboardBacklight

    name: "display"
    title: "Display"
    icon: "brightness_6"
    description: "Brightness, night light, keeping the screen on, and the connected displays."
    sections: [
        {
            title: "Brightness",
            rows: [
                ...(root.screenBacklight.available ? [{
                    type: "slider",
                    label: "Screen",
                    icon: () => BrightnessService.screenIcon,
                    get: () => Math.round(root.screenBacklight.level * 100),
                    set: value => root.screenBacklight.setLevel(value / 100),
                    min: 0,
                    max: 100,
                    step: 1,
                    unit: "%"
                }] : []),
                ...(root.keyboardBacklight.available ? [{
                    type: "slider",
                    label: "Keyboard",
                    icon: () => BrightnessService.keyboardIcon,
                    get: () => Math.round(root.keyboardBacklight.level * 100),
                    set: value => root.keyboardBacklight.setLevel(value / 100),
                    min: 0,
                    max: 100,
                    step: 1,
                    unit: "%"
                }] : []),
                { type: "number", label: "Brightness key step", icon: "keyboard", key: "services.brightnessStepPercent", min: 1, max: 100, step: 1, unit: "%" }
            ]
        },
        {
            title: "Night light",
            rows: [
                { type: "switch", label: "Night light", icon: "nightlight", description: "Warms the screen with hyprsunset.", get: () => NightLightService.enabled, set: value => {
                        if (value !== NightLightService.enabled)
                            NightLightService.toggle();
                    } },
                {
                    type: "slider",
                    label: "Temperature",
                    icon: "thermostat",
                    description: "Lower is warmer.",
                    get: () => NightLightService.temperature,
                    set: value => NightLightService.setTemperature(value),
                    min: NightLightService.warmest,
                    max: NightLightService.coolest,
                    step: NightLightService.step,
                    unit: "K"
                }
            ]
        },
        {
            title: "Power",
            rows: [
                { type: "switch", label: "Keep awake", icon: "coffee", description: "Stops the screen from dimming, locking or sleeping.", get: () => KeepAwakeService.enabled, set: value => {
                        if (value !== KeepAwakeService.enabled)
                            KeepAwakeService.toggle();
                    } }
            ]
        },
        {
            title: "Displays",
            rows: Quickshell.screens.map(screen => ({
                type: "info",
                label: screen.name,
                icon: "monitor",
                description: [screen.manufacturer, screen.model].filter(part => part).join(" "),
                get: () => `${screen.width} × ${screen.height} · ${Math.round(screen.devicePixelRatio * 100)}%`
            }))
        }
    ]
}

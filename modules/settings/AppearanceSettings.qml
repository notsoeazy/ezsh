import QtQuick

import qs.themes
import qs.services

SettingsPage {
    id: root

    name: "appearance"
    title: "Appearance"
    icon: "palette"
    description: "Colors and wallpaper."
    sections: [
        {
            title: "Theme",
            rows: [
                { type: "action", label: "Color theme", description: () => Theme.shown?.name ?? "Default", button: "Choose", run: () => ViewService.open("theme") },
                { type: "switch", label: "Dark mode", description: "Themes without a light palette stay dark.", get: () => Theme.dark, set: value => ThemeService.set(ThemeService.current, value ? "dark" : "light") },
                {
                    type: "text",
                    label: "Color files folder",
                    description: "Where the Hyprland, terminal and GTK color files go. Empty keeps them in ezsh's state folder; ~/.config puts them next to each app's config.",
                    key: "theme.outputDirectory",
                    placeholder: "~/.local/state/ezsh/generated",
                    allowEmpty: true
                }
            ]
        },
        {
            title: "Wallpaper",
            rows: [
                { type: "switch", label: "Show the wallpaper", description: "Off leaves the desktop to another wallpaper tool.", key: "wallpaper.enabled" },
                { type: "action", label: "Wallpaper", description: "Browse the wallpaper folder.", button: "Choose", run: () => ViewService.open("wallpaper") },
                { type: "text", label: "Wallpaper folder", description: "Searched with its subfolders for JPG, PNG and WebP images.", key: "wallpaper.directory", placeholder: "~/Pictures/Wallpapers" }
            ]
        }
    ]
}

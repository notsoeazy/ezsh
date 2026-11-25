import QtQuick

import qs.config

SettingsPage {
    id: root

    name: "about"
    title: "About"
    icon: "info"
    description: "ezsh keeps every setting in one file, and edits to it apply right away."
    sections: [
        {
            title: "",
            rows: [
                { type: "info", label: "Settings file", description: Config.path }
            ]
        }
    ]
}

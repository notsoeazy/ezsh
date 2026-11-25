import QtQuick

// One settings page: what the sidebar shows, and its settings as data, so search reaches every row
// without building the page. SettingRow describes the row objects.
QtObject {
    id: root

    // Its id for `qs ipc call settings openPage <name>`.
    property string name: ""
    property string title: ""
    property string icon: ""
    property string description: ""
    // The window is showing this page (not search results); pages scan only while shown.
    property bool shown: false
    // [{ title, rows: [row, ...] }]; a section with no title shows only its card.
    property var sections: []
}

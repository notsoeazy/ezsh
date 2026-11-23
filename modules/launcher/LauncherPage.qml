import QtQuick

import qs

QtObject {
    property string placeholder: "Search"
    property string icon: "search"
    property string emptyText: "No results"
    property string emptyIcon: "search_off"
    property string actionHint: "open"
    property int rowHeight: Tokens.launcher.rowHeight
    property Component row

    function prepare() {
    }

    function results(query) {
        return [];
    }

    function activate(entry, launcher) {
    }
}

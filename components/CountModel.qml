import QtQuick

// A model of `size` empty entries that grows and shrinks at its end. A Repeater over it keeps the
// delegates it already has when the size changes (a plain number as model rebuilds them all), so
// delegates that read their data by index (SettingsGroup's rows) survive a list refresh.
ListModel {
    id: root

    property int size: 0

    function sync() {
        while (root.count < root.size)
            root.append({});
        if (root.count > root.size)
            root.remove(root.size, root.count - root.size);
    }

    onSizeChanged: root.sync()
    Component.onCompleted: root.sync()
}

.pragma library

// Active SSID from `nmcli -t -g ACTIVE,SSID dev wifi list` output ("" if none).
// Terse mode escapes ':' and '\' in values with a backslash, so undo that.
function activeSsid(text) {
    const line = text.split("\n").find(l => l.startsWith("yes:"));
    return line ? line.slice(4).replace(/\\(.)/g, "$1") : "";
}

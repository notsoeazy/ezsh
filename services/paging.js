.pragma library

// First workspace id before the page that holds `id`: pages of `size` are 1..size, size+1..2*size, ...
// Ids below 1 (special workspaces) fall back to the first page.
function pageStart(id, size) {
    if (id < 1 || size < 1)
        return 0;
    return Math.floor((id - 1) / size) * size;
}

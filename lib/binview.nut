/**
 * Util: returns binary view of data
 * @param {number|number[]} d
 */
function binview(d) {

    if ("array" != type(d)) {
        d = [d];
    }

    local r = "";

    for (local i = 0; i < d.len(); i++) {
        local v = d[i];

        for (local d = 0; d < 8; d++) {
            r += this._getBit(v, d);
        }

        r += " ";
    }

    return r;
}

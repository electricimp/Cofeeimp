// libs
@include once "github:electricimp/Promise/Promise.class.nut@v2.0.0"

// Coffeeimp class
@include "Coffeeimp.nut"

//

function main() {
    // enable powersave mode
    imp.setpowersave(true);

    local m = Coffeeimp(hardware.uart12);
//    m.sendCommand("RT:0000").then(@(v) server.log(v), @(e) server.error(e));
//    m.dumpEEPROM(0, 16 * 2, false).then(@(v) server.log(v), @(e) server.error(e));
    m.getEspressosCount().then(@(v) server.log(v), @(e) server.error(e));
}

main();

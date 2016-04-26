// libs
@include once "github:electricimp/Promise/Promise.class.nut@v2.0.0"

// Coffeeimp class
@include "Coffeeimp.nut"

//

function main() {
    // enable powersave mode
    imp.setpowersave(true);

    local m = Coffeeimp(hardware.uart12);

    m.sendCommand("TY:")
        .then(function (result) {
            server.log(result);
        });
}

main();

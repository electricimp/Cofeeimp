// libs
@include once "github:electricimp/Promise/Promise.class.nut@v2.0.0"
@include once "github:electricimp/JSONEncoder/JSONEncoder.class.nut@v0.6.0"

// Coffeeimp class
@include "Coffeeimp.nut"

//

function main() {
    imp.setpowersave(true);
    machine <- Coffeeimp(hardware.uart12);
    readCounters();
}

/**
 * Read/send counters
 */
function readCounters() {
    local res = {};

    local countersPromises = [
        @() machine.getEspressosCount().then(@(v) res.espressos <- v),
        @() machine.getRistrettosCount().then(@(v) res.ristrettos <- v),
        @() machine.getCoffeesCount().then(@(v) res.coffees <- v),
        @() machine.getCappuccinosCount().then(@(v) res.cappuccinos <- v),
        @() machine.getLatteMacchiatosCount().then(@(v) res.latteMacchiatos <- v),
        @() machine.get2EspressosCount().then(@(v) res.twoEspressos <- v),
        @() machine.get2RistrettosCount().then(@(v) res.twoRistrettos <- v),
        @() machine.get2CoffeesCount().then(@(v) res.twoCoffees <- v)
    ];

    Promise.serial(countersPromises)
        .then(function (v) {
            server.log("counters: " + JSONEncoder.encode(res))
            agent.send("counters", res) // send to agent
            imp.wakeup(15, readCounters) // repeat
        });
}

main();

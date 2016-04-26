// libs
@include once "github:electricimp/Rocky/Rocky.class.nut@v1.2.3"
@include once "github:electricimp/Promise/Promise.class.nut@v2.0.0"
@include once "github:electricimp/Firebase/firebase.agent.nut@v1.1.1"

//

function main() {
    device.on("counters", function (data) {
        server.log(http.jsonencode(data));
    });
}

main();

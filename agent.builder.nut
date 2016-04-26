// libs
@include once "github:electricimp/Firebase/firebase.agent.nut@v1.1.1"
@include once "github:electricimp/Promise/Promise.class.nut@v2.0.0"

//

function main() {
    device.on("counters", function (data) {
        server.log(http.jsonencode(data));
    });
}

main();

// libs
@include once "github:electricimp/Rocky/Rocky.class.nut@v1.2.3"
@ @include once "github:electricimp/Promise/Promise.class.nut@v2.0.0"
@ @include once "github:electricimp/Firebase/firebase.agent.nut@v1.1.1"

//

function main() {
    coffeeData <- null;

    device.on("counters", function (data) {
        coffeeData <- data;
    });

    // init rocky app
    app <- Rocky();
    app.get("/", onGetRoot);
    app.post("/make", onPostMake);
}

// GET /
function onGetRoot(context) {
    context.setHeader("content-type", "text/html");
    context.send(
@"
        <head>
            <meta charset='UTF-8'>
            <meta name='viewport' content='width=device-width, initial-scale=1'>
            <style>
                body {
                    padding: 10;
                    text-align: center;
                }
                *, input {
                    font-family: sans-serif;
                    font-size: 12pt;
                }
                input {
                    font-size: 12pt;
                    font-weight: bolder;
                    padding: 16px;
                    zoom: 1.1;
                    background: white;
                    border: 2px solid rgb(82, 82, 82);
                    border-radius: 50%;
                    margin: 10px;
                    min-width: 125px;
                }
            </style>
        </head>
        <body>"
            + (coffeeData
                ? http.jsonencode(coffeeData)
                : "–"
            ) + @"
            <br><br>
            <form method=POST action=" + http.agenturl() + @"/make>
                <input type=submit name=type value=Milk><br>
                <input type=submit name=type value=Ristretto>
                <input type=submit name=type value=Espresso>
                <input type=submit name=type value=Capuccino>
                <input type=submit name=type value=Latte>
                <input type=submit name=type value=Coffee>
                <script>// setTimeout(() => location.reload(), 3000)</script>
            </form>
        </body>
"
    );
}

// POST /make
function onPostMake(context) {
    local type = context.req.body.type;
    server.log("Requested " + type);
//    device.send("switchPower", on);
    context.setHeader("location",  http.agenturl());
    context.send(301, "OK");
}

main();

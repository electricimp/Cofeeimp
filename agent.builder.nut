// libs
@include once "github:electricimp/Rocky/Rocky.class.nut@v1.2.3"
//

const MYKEY = "miem0uoT"

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

    if (!(MYKEY in context.req.query)) {
         context.send("Authorization required");
         return;
    }

    local caffeine = coffeeData ? coffeeData.ristrettos * 75
        + coffeeData.espressos * 75
        + coffeeData.twoCoffees * 75 * 2
        + coffeeData.latteMacchiatos * 75
        + coffeeData.twoRistrettos * 75 * 2
        + coffeeData.cappuccinos * 75
        + coffeeData.twoEspressos * 75 * 2
        + coffeeData.coffees * 75 : 0;

    caffeine = (caffeine / 1000) + "," + format("%03d", caffeine % 1000);

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
                    background-image: url(https://electricimp.com/favicon.ico);
                    background-size: 64px;
                    background-repeat: no-repeat;

                }
                *, input {
                    font-family: 'Helvetica Neue', sans-serif;
                    font-size: 10pt;
                }
                input {
                    font-size: 12pt;
                    font-weight: 400;
                    text-transform: uppercase;
                    letter-spacing: 0px;
                    padding: 14px;
                    zoom: 1.1;
                    background: white;
                    border: 2px solid #4A4A4A;
                    border-radius: 50%;
                    margin: 10px;
                    min-width: 122px;
                    color: #4A4A4A;
                    cursor: pointer;
                }
            </style>
        </head>
        <body>
            <div style='position:absolute;opacity:0.5;width:65px;height:65px;background:white;left:0;top:0'></div>
            <br><br><br>
            <form method=POST action=" + http.agenturl() + "/make?" + MYKEY + @">
                <input type=submit name=type value=Ristretto>
                <input type=submit name=type value=Espresso><br>
                <input type=submit name=type value=Cappuccino>
                <input type=submit name=type value=Latte><br>
                <input type=submit name=type value=Coffee>
                <input type=submit name=type value=Milk><br>
                <input type=submit name=type value='Useless Button'>
                <script> setTimeout(() => location.reload(), 10000)</script>
            </form><br><br>
<div style='font-size:150%;color:gray'>" + caffeine + @" mg<div style='font-size:75%;margin-top:10px'>caffeine consumed</div></div>
        </body>
"
    );
}

// POST /make
function onPostMake(context) {

    if (!(MYKEY in context.req.query)) {
         context.send("Authorization required");
         return;
    }

    local type = context.req.body.type;
    server.log("Requested " + type);
    device.send("request", type);
    context.setHeader("location",  http.agenturl() + "?" + MYKEY);
    context.send(301, "OK");
}

main();

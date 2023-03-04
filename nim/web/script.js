var initial_script = `
{
"simulation": {
    "eps": 1e-6,
    "dt": 1e-2,
    "max_steps": 1000000,
    "equal_time": false,
    "accuracy": false,
    "linear": false,
    "record_objects": true
},
"objects": [
    { 
        "type": "tri-lattice", "rows": 4, "columns": 8, 
        "object": { "type": "circle", "pos": [ 0.5, 0.5], "rad": 0.45, "damp": 0.95}
    }
],
"particles": [ { "type": "single", "pos": [4.0, 6.6], "vel": [0.1, 0.0] } ],
"forces": [ { "type": "gravity", "g": -1.0 } ],
"interrupts": [ { "type": "collision", "object": { "type": "ref", "name": "bottom" } } ],
"observers": [
    {
        "type": "pgm", 
        "filename": "canvas", 
        "format": "pgm5",
        "blend": "add",
        "box": { "type": "ref", "name": "boundary"},
        "resolution": 2000
    },
    { "type": "step", "interval": 1000 }
]
}`;

document.getElementById("source").value = initial_script;
var canvas = document.getElementById("canvas");
canvas.width = canvas.clientWidth;
canvas.height = canvas.clientHeight;

var run_button = document.getElementById("run");
run_button.onclick = function () {
    var canvas = document.getElementById("canvas");
    var offscreen = canvas.transferControlToOffscreen();

    var json = document.getElementById("source").value;
    var worker = new Worker("worker.js" + '?' + Math.random());
    worker.addEventListener("message", function handleMessageFromWorker(msg) {
        const data = msg.data;
        if (data === "done") {

        } else {
            var log = document.getElementById("log");
            log.value += data + "\n";
            log.scrollTop = log.scrollHeight;
        }
    });
    worker.postMessage({ json: json, canvas: offscreen }, [offscreen]);
}

var reset_button = document.getElementById("reset");
reset_button.onclick = function () {
    var newcanvas = document.createElement('canvas');
    var oldcanvas = document.getElementById('canvas');
    newcanvas.id = oldcanvas.id;
    newcanvas.width = oldcanvas.width;
    newcanvas.height = oldcanvas.height;
    newcanvas.style = oldcanvas.style;
    oldcanvas.replaceWith(newcanvas);
    document.getElementById("log").value = "";
}

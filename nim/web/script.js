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
var offscreen = canvas.transferControlToOffscreen();

var run_button = document.getElementById("run");

const console_log = window.console.log;
window.console.log = function (...args) {
    console_log(...args);
    var textarea = document.getElementById('log');
    console_log(textarea);
    if (!textarea) {
        console_log('nothing');
        return;
    }
    args.forEach(arg => textarea.value += `${JSON.stringify(arg)}\n`);
}

run_button.onclick = function () {
    var json = document.getElementById("source").value;
    var worker = new Worker("worker.js");
    worker.postMessage({ json: json, canvas: offscreen }, [offscreen]);
}

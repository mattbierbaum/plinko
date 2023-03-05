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
        "object": {
            "type": "circle",
            "pos": [ 0.5, 0.5],
            "rad": 0.45,
            "damp": 0.95
        }
    }
],
"particles": [
    {
        "type": "single",
        "pos": [4.0, 6.6],
        "vel": [0.1, 0.0]
    }
],
"forces": [ { "type": "gravity", "g": -1.0 } ],
"interrupts": [
    {
        "type": "collision",
        "object": {
            "type": "ref",
            "name": "bottom"
        }
    }
],
"observers": [
    {
        "type": "pgm",
        "filename": "canvas",
        "blend": "add",
        "box": { "type": "ref", "name": "boundary"}
    },
    { "type": "step", "interval": 1000 }
]
}`;

var worker = null;
document.getElementById("source").value = initial_script;

function reset() {
    var newcanvas = document.createElement('canvas');
    var oldcanvas = document.getElementById('canvas');
    newcanvas.id = oldcanvas.id;
    newcanvas.width = oldcanvas.width;
    newcanvas.height = oldcanvas.height;
    newcanvas.style = oldcanvas.style;
    oldcanvas.replaceWith(newcanvas);
    document.getElementById("log").value = "";
}

var run_button = document.getElementById("run");
run_button.onclick = function () {
    if (run_button.textContent === "Run") {
        reset();

        var zoom = parseInt(document.getElementById("zoom").value);
        var canvas = document.getElementById("canvas");
        canvas.width = zoom * canvas.clientWidth;
        canvas.height = zoom * canvas.clientHeight;
        var offscreen = canvas.transferControlToOffscreen();

        var json = document.getElementById("source").value;
        worker = new Worker("worker.js" + '?' + Math.random());
        worker.addEventListener("message", function handleMessageFromWorker(msg) {
            const data = msg.data;
            if (data.type === "status") {
                if (data.msg === "done") {
                    run_button.textContent = "Run";
                }
            } else if (data.type === "log") {
                var log = document.getElementById("log");
                log.value += data.msg + "\n";
                log.scrollTop = log.scrollHeight;
            } else if (data.type === "ratio") {
                canvas.clientWidth = canvas.clientWidth
                canvas.clientHeight = canvas.clientWidth * data.msg;
            }
        });
        worker.postMessage({ json: json, canvas: offscreen }, [offscreen]);
        run_button.textContent = "Stop";
    } else if (run_button.textContent === "Stop") {
        worker.terminate();
        run_button.textContent = "Run";
    }
}

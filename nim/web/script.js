
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

window.onload = function () {
    var worker = null;

    var s = document.getElementById('presets');
    console.log(examples);
    for (const key in examples) {
        var option = document.createElement("option");
        option.text = key;
        s.add(option);
    }

    var source = document.getElementById("source");
    var presets = document.getElementById("presets");
    presets.onchange = function () {
        var textarea = document.getElementById("source");
        textarea.value = examples[presets.value];
    }

    presets.value = 'plinko-simple';
    source.value = examples[presets.value];

    var run_button = document.getElementById("run");
    run_button.onclick = function () {
        var source = document.getElementById("source");
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
                        source.disabled = false;
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
            source.disabled = true;
        } else if (run_button.textContent === "Stop") {
            worker.terminate();
            run_button.textContent = "Run";
            source.disabled = false;
        }
    }

}
importScripts('js.js' + '?' + Math.random());

self.onmessage = function (evt) {
    if (evt.data.json) {
        setup_logger(function(a){
            postMessage({"type": "log", "msg": a});
        })
        var json = evt.data.json;
        var canvas = evt.data.canvas;
        var sim = create_simulation(json, canvas);

        var ratio = get_canvas_ratio(sim);
        postMessage({"type": "ratio", "msg": ratio})
        log_simulation(sim);
        run_simulation(sim);
        postMessage({"type": "status", "msg": "done"});
    }

    if (evt.data.eventName) {
        console.log(eventName);
    }
};
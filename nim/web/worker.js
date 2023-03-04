importScripts('js.js' + '?' + Math.random());

self.onmessage = function (evt) {
    if (evt.data.json) {
        setup_logger(function(a){
            postMessage(a);
        })
        var json = evt.data.json;
        var canvas = evt.data.canvas;
        var sim = create_simulation(json, canvas);
        log_simulation(sim);
        run_simulation(sim);
        postMessage("done");
    }

    if (evt.data.eventName) {
        console.log(eventName);
    }
};
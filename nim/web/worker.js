importScripts('js.js');

self.onmessage = function (evt) {
    if (evt.data.json) {
        setup_log(function(a){
            postMessage(a)
        })
        var json = evt.data.json;
        var canvas = evt.data.canvas;
        var sim = create_simulation(json, canvas);
        run_simulation(sim);
    }

    // pass incoming events into the stage
    if (evt.data.eventName) {
        console.log(eventName);
    }
};
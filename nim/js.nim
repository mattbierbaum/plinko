# import nimprof

import log
import ics
import observers_js
import simulation

proc create_simulation*(json: cstring, canvas: Canvas): Simulation {.exportc.} =
    let sim = json_to_simulation($json)
    for obs in sim.observers:
        obs.set_canvas(canvas)
    sim.initialize()
    return sim

proc get_canvas_ratio*(sim: Simulation): float {.exportc.} =
    var ratio = 0.0
    for obs in sim.observers:
        ratio = max(ratio, obs.get_canvas_ratio())
    return ratio

proc log_simulation*(sim: Simulation): void {.exportc.} =
    if sim.verbose:
        echo $sim

proc run_simulation*(sim: Simulation): void {.exportc.} =
    echo "Starting simulation..."
    discard sim.run()
    echo "Saving observers..."
    sim.close()
    echo "Done."

proc setup_logger*(logger: proc (txt: cstring): void): void {.exportc.} =
    let string_logger: LogFunction = proc(itxt: string): void =
        logger(itxt.cstring)
    set_logger(string_logger)

proc nim_log*(txt: cstring): void =
    echo $txt
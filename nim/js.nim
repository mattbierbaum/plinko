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

proc log_simulation*(sim: Simulation): void {.exportc.} =
    echo $sim

proc run_simulation*(sim: Simulation): void {.exportc.} =
    sim.run()
    sim.close()

proc setup_logger*(logger: proc (txt: cstring): void): void {.exportc.} =
    let string_logger: LogFunction = proc(itxt: string): void =
        logger(itxt.cstring)
    set_logger(string_logger)
# import nimprof

proc simple_echo(txt: cstring): void = echo $txt
var log_func: proc(txt: cstring): void = simple_echo
proc echo*(txt: string): void = log_func(txt.cstring)

import ics
import observers_js
import simulation

proc create_simulation*(json: cstring, canvas: Canvas): Simulation {.exportc.} =
    let sim = json_to_simulation($json)
    for obs in sim.observers:
        obs.set_canvas(canvas)
    sim.initialize()
    return sim

proc run_simulation*(sim: Simulation): void {.exportc.} =
    sim.run()
    sim.close()
    echo $sim

proc setup_log*(logger: proc (txt: cstring): void): void {.exportc.} =
    log_func = logger
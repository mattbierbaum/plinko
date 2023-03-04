# import nimprof

import ics
import observers_js
import simulation

proc create_simulation*(json: cstring, canvas: Canvas): Simulation {.exportc.} =
    let sim = json_to_simulation($json)
    for obs in sim.observers:
        obs.set_canvas(canvas)
    sim.initialize()
    return sim

proc run_simulation(sim: Simulation): void {.exportc.} =
    sim.run()
    sim.close()
    echo $sim
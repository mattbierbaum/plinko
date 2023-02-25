import ics
import simulation

import std/os
import std/strformat
import std/times

let params = commandLineParams()
if len(params) != 1:
    echo "Usage: plinko <simulation.json>"
else:
    let json = open(params[0], fmRead).readAll()
    var sim = json_to_simulation(json)
    echo $sim

    let time_start = times.cpuTime()
    sim.run()
    let time_end = times.cpuTime()
    echo fmt"Step rate (M/sec): {sim.max_steps.float/(time_end-time_start)/1e6}"
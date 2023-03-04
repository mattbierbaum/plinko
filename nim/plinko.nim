# import nimprof

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
    sim.initialize()

    if sim.verbose:
        echo $sim

    var time_start = times.cpuTime()
    sim.run()
    var time_end = times.cpuTime()
    echo fmt"Step rate (M/sec): {sim.max_steps.float/(time_end-time_start)/1e6}"

    time_start = times.cpuTime()
    sim.close()
    time_end = times.cpuTime()
    echo fmt"Close time (sec): {time_end - time_start}"
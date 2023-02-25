import ics
import simulation

import std/os

let params = commandLineParams()
if len(params) != 1:
    echo "Usage: plinko <simulation.json>"
else:
    let json = open(params[0], fmRead).readAll()
    var sim = json_to_simulation(json)
    echo $sim
    sim.run()
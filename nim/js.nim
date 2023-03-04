# import nimprof

import ics
import simulation

proc create_simulation*(json: string): Simulation =
    return json_to_simulation(json)

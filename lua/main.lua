local ics = require('ics')

local s = ics.create_simulation(ics.single_circle2())
local t_start = os.clock()
s:step(1e7)
local t_end = os.clock()
print(t_end - t_start)

local ics = require('ics')

local s = ics.create_simulation(ics.single_circle())
local t_start = os.clock()
s:step(20000)
local t_end = os.clock()
print(t_end - t_start)

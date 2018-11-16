local ics = require('ics')

local s = ics.create_simulation(ics.hexgrid(4, 0.5))
local t_start = os.clock()
--s:step(100000)
s.nbl:show()
local t_end = os.clock()
print(t_end - t_start)

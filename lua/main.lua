local ics = require('ics')

-- https://repo.or.cz/w/luajit-2.0.git/blob_plain/v2.1:/doc/ext_profiler.html#jit_zone
-- fengari.io

local s = ics.create_simulation(ics.single_circle())
local t_start = os.clock()
s:step(9e7)
local t_end = os.clock()
print(t_end - t_start)

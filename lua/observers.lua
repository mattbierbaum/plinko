local util = require('util')

CSVRecorder = util.class()
function CSVRecorder:init(filename)
    self.filename = filename
end

function CSVRecorder:begin()
    self.file = io.open(self.filename, 'w')
end

function CSVRecorder:update(p)
    --local pos = p.pos
    --local vel = p.vel
    --local speed = math.sqrt(vel[1]*vel[1] + vel[2]*vel[2])
    self.file:write(p[1] .. ', ' .. p[2] .. '\n')
end

function CSVRecorder:close()
    self.file:flush()
    self.file:close()
end

return {
    CSVRecorder=CSVRecorder
}

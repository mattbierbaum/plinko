local util = require('util')
local objects = require('objects')

StateFileRecorder = util.class()
function StateFileRecorder:init(filename)
    self.filename = filename
end

function StateFileRecorder:begin()
    self.file = io.open(self.filename, 'w')
end

function StateFileRecorder:update(particle)
    local pos = particle.pos
    local vel = particle.vel
    local acc = particle.acc
    self.file:write(
        pos[1] .. ' ' .. pos[2] .. ' ' ..
        vel[1] .. ' ' .. vel[2] .. ' ' ..
        acc[1] .. ' ' .. acc[2] .. '\n'
    )
end

function StateFileRecorder:close()
    self.file:flush()
    self.file:close()
end


ImageRecorder = util.class()
function ImageRecorder:init(filename, plotter)
    self.filename = filename
    self.plotter = plotter
    self.lastposition = nil
    self.segment = objects.Segment({0,0}, {0,0})
end

function ImageRecorder:begin()
end

function ImageRecorder:update(particle)
    if self.lastposition then
        self.segment.p0[1] = self.lastposition[1]
        self.segment.p0[2] = self.lastposition[2]
        self.segment.p1[1] = particle.pos[1]
        self.segment.p1[2] = particle.pos[2]
        self.plotter:draw_segment(self.segment)
    else
        self.lastposition = {}
    end
    self.lastposition[1] = particle.pos[1]
    self.lastposition[2] = particle.pos[2]
end

function ImageRecorder:close()
    local file = io.open(self.filename, 'w')
    local image = self.plotter:image()
    local shape = self.plotter:shape()

    for j = 1, shape[2] do
        for i = 1, shape[1] do
            file:write(image[i + j*shape[1]] .. ' ')
        end
        file:write('\n')
    end
    file:close()
end

TimePrinter = util.class()

function TimePrinter:init(interval)
    self.interval = interval
end

function TimePrinter:begin()
    self.step = 0
end

function TimePrinter:update(p)
    if self.step % self.interval == 0 then
        print(self.step)
    end

    self.step = self.step + 1
end

function TimePrinter:close()
end

return {
    StateFileRecorder=StateFileRecorder,
    ImageRecorder=ImageRecorder,
    TimePrinter=TimePrinter
}

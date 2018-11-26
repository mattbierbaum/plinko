local util = require('util')
local objects = require('objects')
local struct = require('struct')

-- =================================================================
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

-- =================================================================
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
        self.lastposition[1] = particle.pos[1]
        self.lastposition[2] = particle.pos[2]
    else
        self.lastposition = {particle.pos[1], particle.pos[2]}
    end
end

function ImageRecorder:close()
    local file = io.open(self.filename, 'wb')
    local image = self.plotter:image()
    local shape = self.plotter:shape()

    for j = 0, shape[2]-1 do
        for i = 0, shape[1]-1 do
            file:write(struct.pack('<d', image[i + j*shape[1]]))
        end
    end
    file:close()
end

-- =================================================================
PointImageRecorder = util.class(ImageRecorder)
function PointImageRecorder:init(filename, plotter)
    ImageRecorder.init(self, filename, plotter)
end

function PointImageRecorder:update(particle)
    self.plotter:draw_point(particle.pos)
end

-- =================================================================
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
    PointImageRecorder=PointImageRecorder,
    TimePrinter=TimePrinter
}

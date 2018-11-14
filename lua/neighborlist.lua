local util = require('util')
local vector = require('vector')

-- ==============================================
NaiveNeighborlist = util.class()

function NaiveNeighborlist:init()
    self.objects = {}
end

function NaiveNeighborlist:append(obj)
    self.objects[#self.objects + 1] = obj
end

function NaiveNeighborlist:near(seg)
    return self.objects
end

-- ==============================================
CellNeighborlist = util.class()

function CellNeighborlist:init(box, ncells)
    self.objects = {}

    self.box = box
    self.ncells = ncells
    self.cell = vector.vdivv(vector.vsubv(box.c1, box.c0), self.ncells)

    self.cells = {}
    for i = 1, self.ncells[1] do
        self.cells[i] = {}
    end
end

function CellNeighborlist:cell(i, j)
    local fractx = i / self.ncells[1]
    local fracty = j / self.ncells[2]

    local vx = vector.lerp(self.box.ll, self.box.ul)
    local vy = vector.lerp(self.box.ll, self.box.ul)
end

function CellNeighborlist:append(obj)
    self.objects[#self.objects + 1] = obj


end

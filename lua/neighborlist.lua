local math = require('math')
local util = require('util')
local vector = require('vector')
local objects = require('objects')

local function swap(a, b)
    return b, a
end

-- ==============================================
local NaiveNeighborlist = util.class()

function NaiveNeighborlist:init()
    self.objects = {}
end

function NaiveNeighborlist:append(obj)
    self.objects[#self.objects + 1] = obj
end

function NaiveNeighborlist:calculate()
end

function NaiveNeighborlist:near(seg)
    return self.objects
end

-- ==============================================
local CellNeighborlist = util.class()

function CellNeighborlist:init(box, ncells, buffer)
    local sidelength = math.max(box.uu[1] - box.ll[1], box.uu[2] - box.ll[2])
    self.buffer = buffer or 2/ncells[1]
    self.buffer = self.buffer * sidelength

    self.ncells = ncells
    self.box = objects.Box(
        vector.vsubs(box.ll, self.buffer),
        vector.vadds(box.uu, self.buffer)
    )
    self.cell = {
        (self.box.uu[1] - self.box.ll[1]) / self.ncells[1],
        (self.box.uu[2] - self.box.ll[2]) / self.ncells[2]
    }

    self.objects = {}
    self.seen = {}
    self.cells = {}
    for i = 0, (self.ncells[1]+1)*(self.ncells[2]+1) do
        self.seen[i] = {}
        self.cells[i] = {}
    end
end

function CellNeighborlist:cell_ind(i, j)
    return i + j*self.ncells[1]
end

function CellNeighborlist:cell_box(i, j)
    local fractx = i / self.ncells[1]
    local fracty = j / self.ncells[2]

    local x0 = (1 - fractx) * self.box.ll[1]  + fractx * self.box.uu[1]
    local y0 = (1 - fracty) * self.box.ll[2]  + fracty * self.box.uu[2]
    local x1 = x0 + self.cell[1]
    local y1 = y0 + self.cell[2]
    return objects.Box({x0, y0}, {x1, y1})
end

function CellNeighborlist:point_to_index(p)
    return {
        (p[1] - self.box.ll[1]) / self.cell[1],
        (p[2] - self.box.ll[2]) / self.cell[2]
    }
end

function CellNeighborlist:append(obj)
    self.objects[#self.objects + 1] = obj
end

function CellNeighborlist:calculate()
    for i = 0, self.ncells[1] do
        for j = 0, self.ncells[2] do
            local box = self:cell_box(i, j)

            for k = 1, #box.segments do
                local seg = box.segments[k]
                for l = 1, #self.objects do
                    local obj = self.objects[l]
                    local o, t = obj:intersection(seg)
                    if o then
                        local ind = self:cell_ind(i, j)
                        local s = self.seen[ind]
                        local t = self.cells[ind]

                        if not s[l] then
                            s[l] = true
                            t[#t + 1] = obj
                        end
                    end
                end
            end
        end
    end
end

function CellNeighborlist:near(seg, verbose)
    local verbose = verbose or false
    local box = self.box
    local cell = self.cell
    local x0 = (seg.p0[1] - box.ll[1]) / cell[1]
    local y0 = (seg.p0[2] - box.ll[2]) / cell[2]
    local x1 = (seg.p1[1] - box.ll[1]) / cell[1]
    local y1 = (seg.p1[2] - box.ll[2]) / cell[2]

    local ix0 = math.floor(x0)
    local ix1 = math.floor(x1)
    local iy0 = math.floor(y0)
    local iy1 = math.floor(y1)

    local steep = math.abs(y1 - y0) > math.abs(x1 - x0)

    -- short-circuit things that don't leave a single cell
    if (ix0 == ix1 and iy0 == iy1) then
        return self.cells[self:cell_ind(ix0, iy0)]
    end

    if steep then
        x0, y0 = swap(x0, y0)
        x1, y1 = swap(x1, y1)
    end
    if x0 > x1 then
        x0, x1 = swap(x0, x1)
        y0, y1 = swap(y0, y1)
    end

    local dx = x1 - x0
    local dy = y1 - y0
    local dydx = dy / dx

    local ix0 = math.floor(x0)
    local ix1 = math.ceil(x1)

    local objs = {}
    for x = ix0, ix1 do
        local iy0 = math.floor(dydx * (x - x0) + y0)
        local iy1 = math.floor(dydx * (x + 1 - x0) + y0)

        if steep then
            if iy0 == iy1 then
                self:_addcell(iy0, x, objs)
            else
                self:_addcell(iy0, x, objs)
                self:_addcell(iy1, x, objs)
            end
        else
            if iy0 == iy1 then
                self:_addcell(x, iy0, objs)
            else
                self:_addcell(x, iy0, objs)
                self:_addcell(x, iy1, objs)
            end
        end
    end
    return objs
end

function CellNeighborlist:_addcell(i, j, objs)
    assert(i >= 0 or i <= self.ncells[1] or j >= 0 or j <= self.ncells[2])

    local ind = self:cell_ind(i, j)
    local cell = self.cells[ind]
    for c = 1, #cell do
        objs[#objs + 1] = cell[c]
    end
end

function CellNeighborlist:show()
    io.write('|')
    for i = 1, self.ncells[1] do
        io.write('-')
    end
    io.write('|')
    io.write('\n')

    for j = self.ncells[2], 0, -1 do
        io.write('|')
        for i = 0, self.ncells[1] do
            if #self.cells[self:cell_ind(i, j)] > 0 then
                io.write('*')
            else
                io.write(' ')
            end

        end
        io.write('|')
        io.write('\n')
    end

    io.write('|')
    for i = 1, self.ncells[1] do
        io.write('-')
    end
    io.write('|')
    io.write('\n')
end

return {
    NaiveNeighborlist=NaiveNeighborlist,
    CellNeighborlist=CellNeighborlist
}

--[[
-- psuedo code for neighborlisting arbitrary objects:
--   - each object has a parametric representation (x(t), y(y))
--   - step along the curve and find edges that intersect, adding the object to the nodes
--      * initial condition t0 = (x0, y0)
--      * find segments surrounding and find earliest intersection (store t_cross_obj, t_cross_seg) (add object to node)
--      * try all 6 neighboring edges and find next intersection (later than t_cross_obj)
--      * continue until no more crossings
--]]

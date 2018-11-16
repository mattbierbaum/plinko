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
    return self.objects, #self.objects
end

-- ==============================================
local CellNeighborlist = util.class()

function CellNeighborlist:init(box, ncells)
    self.objects = {}

    self.box = box
    self.ncells = ncells
    self.cell = {
        (box.uu[1] - box.ll[1]) / self.ncells[1],
        (box.uu[2] - box.ll[2]) / self.ncells[2]
    }

    self.seen = {}
    self.cells = {}
    for i = 1, (self.ncells[1]+1)*(self.ncells[2]+1) do
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
    self.nnear = 0
    self.near_objs = {}
    self.near_seen = {}

    for i = 1, #self.objects do
        self.near_objs[i] = 0
        self.near_seen[i] = false
    end
end

function CellNeighborlist:calculate()
    for i = 1, self.ncells[1] do
        for j = 1, self.ncells[2] do
            local box = self:cell_box(i, j)

            for k = 1, #box.segments do
                local seg = box.segments[k]
                for l = 1, #self.objects do
                    local obj = self.objects[l]
                    if obj:intersection(seg) then
                        local ind = self:cell_ind(i, j)
                        local s = self.seen[ind]
                        local t = self.cells[ind]

                        if not s[l] then
                            s[l] = true
                            t[#t + 1] = l
                        end
                    end
                end
            end
        end
    end
end

function CellNeighborlist:near(seg)
    local x0 = (seg.p0[1] - self.box.ll[1]) / self.cell[1]
    local y0 = (seg.p0[2] - self.box.ll[2]) / self.cell[2]
    local x1 = (seg.p1[1] - self.box.ll[1]) / self.cell[1]
    local y1 = (seg.p1[2] - self.box.ll[2]) / self.cell[2]

    self.nnear = 0
    for i = 1, #self.objects do
        self.near_objs[i] = 0
        self.near_seen[i] = false
    end

    local steep = math.abs(y1 - y0) > math.abs(x1 - x0)

    -- short-circuit things that don't leave a single cell
    if (math.floor(x0) == math.floor(x1) and
        math.floor(y0) == math.floor(y1)) then
        self:_addcell(math.floor(x0), math.floor(y0))
        return self.near_objs, self.nnear
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

    for x = ix0, ix1 do
        local iy0 = math.floor(dydx * (x - x0) + y0)
        local iy1 = math.floor(dydx * (x + 1 - x0) + y0)

        if steep then
            if iy0 == iy1 then
                self:_addcell(iy0, x)
            else
                self:_addcell(iy0, x)
                self:_addcell(iy1, x)
            end
        else
            if iy0 == iy1 then
                self:_addcell(x, iy0)
            else
                self:_addcell(x, iy0)
                self:_addcell(x, iy1)
            end
        end
    end

    return self.near_objs, self.nnear
end

function CellNeighborlist:_addcell(i, j)
    local ind = self:cell_ind(i, j)
    local cell = self.cells[ind]
    for c = 1, #cell do
        local o = cell[c]

        if not self.near_seen[o] then
            self.nnear = self.nnear + 1
            self.near_seen[o] = true
            self.near_objs[self.nnear] = self.objects[o]
        end
    end
end

function CellNeighborlist:show()
    for i = 1, self.ncells[1] do
        for j = 1, self.ncells[2] do
            if #self.cells[i][j] > 0 then
                io.write('*')
            else
                io.write(' ')
            end

        end
        io.write('\n')
    end
end

function test()
    local c = CellNeighborlist(objects.Box({0, 0}, {1, 1}), {100, 100})
    c:append(objects.Circle({0.5, 0.5}, 0.25))
    c:calculate()
    local seg = objects.Segment({0.11, 0.1}, {0.5, 0.5})
    for i = 1, 1000000 do
        c:near(seg)
    end
end

function test2()
    c = CellNeighborlist(objects.Box({0, 0}, {1, 1}), {100, 100})
    c:append(objects.Circle({0.5, 0.5}, 0.25))
    c:calculate()
    util.tprint(c:near(objects.Segment({0.5, 0.26}, {0.5, 0.23})))
end

function test3()
    c = CellNeighborlist(objects.Box({0,0}, {1,1}), {100, 100})
    c:append(objects.Circle({0.5, 0.5}, 0.25))
    c:calculate()
    util.tprint(c.cell)
    seg = objects.Segment({0.48111+0.2501, 0.4802}, {0.5233+0.2501, 0.4907})
    util.tprint(c:near(seg))

    seg = objects.Segment({0.49111+0.2501, 0.4802}, {0.5233+0.2501, 0.0907})
    util.tprint(c:near(seg))

    seg = objects.Segment({0.500111+0.25, 0.4802}, {0.500111+0.25, 0.8907})
    util.tprint(c:near(seg))

    seg = objects.Segment({0.300111+0.25, 0.5}, {0.600111+0.25, 0.5})
    util.tprint(c:near(seg))
end

--test() 

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
--
-- or the naive way (already done here):
--   - step through each cell
--   - if object crosses any segment, add to node
--]]

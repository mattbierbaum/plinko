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

function CellNeighborlist:init(box, ncells)
    self.objects = {}

    self.box = box
    self.ncells = ncells
    self.cell = vector.vdivv(vector.vsubv(box.uu, box.ll), self.ncells)

    self.cells = {}
    for i = 1, self.ncells[1] do
        self.cells[i] = {}
        for j = 1, self.ncells[2] do
            self.cells[i][j] = {}
        end
    end
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
    return vector.vdivv(vector.vsubv(p, self.box.ll), self.cell)
end

function CellNeighborlist:append(obj)
    self.objects[#self.objects + 1] = obj
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
                        --util.tprint(box)
                        local t = self.cells[i][j]
                        t[#t + 1] = l
                    end
                end
            end
        end
    end
end

function CellNeighborlist:near(seg)
    local p0 = self:point_to_index(seg.p0)
    local p1 = self:point_to_index(seg.p1)

    return self:objects_on_line(p0, p1)
end

function CellNeighborlist:_addcell(i, j, obj, seen)
    print(i, j)
    if self.cells[i] and self.cells[i][j] then
        local cell = self.cells[i][j]
            util.tprint(cell)
        for c = 1, #cell do
            local ind = cell[c]

            print(i, j, c, ind)
            if not seen[ind] then
                seen[ind] = true
                obj[#obj + 1] = self.objects[ind]
            end
        end
    end
end


function CellNeighborlist:objects_on_line(p0, p1)
    local output = {} -- the list of objects to return
    local seen = {}   -- array to keep track of which objects are in list

    local x0, y0, x1, y1 = p0[1], p0[2], p1[1], p1[2]
    local steep = math.abs(y1 - y0) > math.abs(x1 - x0)

    print(x0, y0, x1, y1)
    util.tprint(self.cells[math.floor(x0)-1][math.floor(y0)-1])
    util.tprint(self.cells[math.floor(x0)][math.floor(y0)-1])
    util.tprint(self.cells[math.floor(x0)][math.floor(y0)])
    util.tprint(self.cells[math.floor(x0)][math.floor(y0)+1])
    util.tprint(self.cells[math.floor(x0)+1][math.floor(y0)])
    util.tprint(self.cells[math.floor(x0)+1][math.floor(y0)+1])

    -- short-circuit things that don't leave a single cell
    if math.floor(x0) == math.floor(x1) and math.floor(y0) == math.floor(y1) then
        self:_addcell(math.floor(x0), math.floor(y0), output, seen)
        return output
    end

    if steep then
        x0, y0 = swap(x0, y0)
        x1, y1 = swap(x1, y1)
    end
    if x0 > x1 then
        x0, x1 = swap(x0, x1)
        y0, y1 = swap(y0, y1)
    end

    print(x0, y0)
    print(x1, y1)
    local dx = x1 - x0
    local dy = y1 - y0
    local gradient = dy / dx
    if dx == 0.0 then
        gradient = 1.0
    end

    local xend = math.floor(x0 + 0.5)
    local yend = y0 + gradient * (xend - x0)
    local xpxl1 = xend
    local ypxl1 = math.floor(yend)
    if steep then
        self:_addcell(ypxl1, xpxl1, output, seen)
        self:_addcell(ypxl1+1, xpxl1, output, seen)
    else
        self:_addcell(xpxl1, ypxl1, output, seen)
        self:_addcell(xpxl1, ypxl1+1, output, seen)
    end
    local intery = yend + gradient

    xend = math.floor(x1 + 0.5)
    yend = y1 + gradient * (xend - x1)
    local xpxl2 = xend
    local ypxl2 = math.floor(yend)
    if steep then
        self:_addcell(ypxl2, xpxl2, output, seen)
        self:_addcell(ypxl2+1, xpxl2, output, seen)
    else
        self:_addcell(xpxl2, ypxl2, output, seen)
        self:_addcell(xpxl2, ypxl2+1, output, seen)
    end

    if steep then
        for x = xpxl1 + 1, xpxl2 - 1 do
           self:_addcell(math.floor(intery), x, output, seen)
           self:_addcell(math.floor(intery)+1, x, output, seen)
           intery = intery + gradient
        end
    else
        for x = xpxl1 + 1, xpxl2 - 1 do
           self:_addcell(x, math.floor(intery), output, seen)
           self:_addcell(x, math.floor(intery)+1, output, seen)
           intery = intery + gradient
        end
    end

    return output
end

function CellNeighborlist:show()
    for i = 1, self.ncells[1] do
        for j = 1, self.ncells[2] do
            if i == 27 and j == 37 then
                io.write('_')
                break
            end

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
    c = CellNeighborlist(objects.Box({0, 0}, {1, 1}), {100, 100})
    c:append(objects.Circle({0.5, 0.5}, 0.25))
    c:calculate()
    for i = 1, 1000000 do
        c:near(objects.Segment({0.11, 0.1}, {0.5, 0.5}))
    end
end

function test2()
    c = CellNeighborlist(objects.Box({0, 0}, {1, 1}), {100, 100})
    c:append(objects.Circle({0.5, 0.5}, 0.25))
    c:calculate()
    util.tprint(c:near(objects.Segment({0.5, 0.26}, {0.5, 0.23})))
end

--function test3()
    c = CellNeighborlist(objects.Box({0,0}, {1,1}), {100, 100})
    c:append(objects.Circle({0.5, 0.5}, 0.25))
    c:calculate()
    util.tprint(c.cell)
    --c:show()
    --seg = objects.Segment({0.67296467966958,0.32051203595316}, {0.6786790016708,0.32186511031134})
    seg = objects.Segment({0.33117937670757,0.32219244818272}, {0.32669244582922,0.3189399543652})
    util.tprint(c:near(seg))
--end

--test3() 

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

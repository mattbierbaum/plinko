local math = require('math')
local util = require('util')
local vector = require('vector')
local objects = require('objects')

function pixels_on_line(p0, p1)
    local pixels = {}
    local append = function(x, y) pixels[#pixels + 1] = {x, y} end
    local swap = function(a, b) return b, a end

    local x0, y0, x1, y1 = p0[1], p0[2], p1[1], p1[2]
    local steep = math.abs(y1 - y0) > math.abs(x1 - x0)

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
    local gradient = dy / dx
    if dx == 0.0 then
        gradient = 1.0
    end

    local xend = math.floor(x0 + 0.5)
    local yend = y0 + gradient * (xend - x0)
    local xpxl1 = xend
    local ypxl1 = math.floor(yend)
    if steep then
        append(ypxl1, xpxl1)
        append(ypxl1+1, xpxl1)
    else
        append(xpxl1, ypxl1)
        append(xpxl1, ypxl1+1)
    end
    local intery = yend + gradient

    xend = math.floor(x1 + 0.5)
    yend = y1 + gradient * (xend - x1)
    local xpxl2 = xend
    local ypxl2 = math.floor(yend)
    if steep then
        append(ypxl2, xpxl2)
        append(ypxl2+1, xpxl2)
    else
        append(xpxl2, ypxl2)
        append(xpxl2, ypxl2+1)
    end

    if steep then
        for x = xpxl1 + 1, xpxl2 - 1 do
           append(math.floor(intery), x)
           append(math.floor(intery)+1, x)
           intery = intery + gradient
        end
    else
        for x = xpxl1 + 1, xpxl2 - 1 do
           append(x, math.floor(intery))
           append(x, math.floor(intery)+1)
           intery = intery + gradient
        end
    end

    return pixels
end

-- ==============================================
NaiveNeighborlist = util.class()

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
CellNeighborlist = util.class()

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

    local x0 = fractx * self.box.ll[1]  + (1 - fractx) * self.box.uu[1]
    local y0 = fracty * self.box.ll[2]  + (1 - fracty) * self.box.uu[2]
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
                        local t = self.cells[i][j]
                        t[#t + 1] = obj
                    end
                end
            end
        end
    end
end

function CellNeighborlist:near(seg)
    local p0 = self:point_to_index(seg.p0)
    local p1 = self:point_to_index(seg.p1)

    local objects = {}
    local pixels = pixels_on_line(p0, p1)
    for i = 1, #pixels do
        local pix = pixels[i]
        local pi, pj = pix[1], pix[2]
        if self.cells[pi] and self.cells[pi][pj] then
            local cell = self.cells[pi][pj]
            for j = 1, #cell do
                objects[cell[j]] = true
            end
        end
    end

    local obj = {}
    for o, _ in pairs(objects) do
        obj[#obj + 1] = o
    end
    return obj
end

function test()
    for i = 1, 10 do
        c = CellNeighborlist(objects.Box({0, 0}, {1, 1}), {100, 100})
        c:append(objects.Circle({0.5, 0.5}, 0.25))
        c:calculate()
        c:near(objects.Segment({0.11, 0.1}, {0.5, 0.5}))
    end
end

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

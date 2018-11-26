local math = require('math')
local util = require('util')
local objects = require('objects')

local ffi_loaded, ffi = pcall(require, 'ffi')

if not ffi_loaded then
    function create_array(size)
        local S = size[1]*size[2]
        local out = {}
        for i = 0, S-1 do
            out[i] = 0
        end
        return out
    end
else
    ffi.cdef[[
        void *malloc(size_t size);
        size_t free(void*);
    ]]

    function create_array(size)
        local S = size[1]*size[2]
        local out = ffi.gc(
            ffi.cast('double*', ffi.C.malloc(ffi.sizeof('double')*S)),
            ffi.C.free
        )
        for i = 0, S-1 do
            out[i] = 0
        end
        return out
    end
end

function ipart(x) return math.floor(x) end
function round(x) return ipart(x + 0.5) end
function fpart(x) return x - math.floor(x) end
function rfpart(x) return 1 - fpart(x) end

function swap(a, b)
    return b, a
end

-- ========================================================
DensityPlot = util.class()

function DensityPlot:init(box, dpi)
    self.box = box
    self.dpi = dpi
    self.N = {
        math.floor(self.dpi * (self.box.uu[1] - self.box.ll[1])),
        math.floor(self.dpi * (self.box.uu[2] - self.box.ll[2]))
    }
    self.grid = create_array(self.N)
end

function DensityPlot:pixel_size()
    return 1 / self.dpi
end

function DensityPlot:_plot(x, y, c)
    if x < 0 or x >= self.N[1] or y < 0 or y >= self.N[2] then
        return
    end

    local x = math.floor(x)
    local y = math.floor(y)
    local ind = x + y*self.N[1]
    self.grid[ind] = self.grid[ind] + c
end

function DensityPlot:_plot_line(x0, y0, x1, y1)
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
    if dx == 0 then
        gradient = 1.0
    end

    local xend = round(x0)
    local yend = y0 + gradient * (xend - x0)
    local xgap = rfpart(x0 + 0.5)
    local xpxl1 = xend
    local ypxl1 = ipart(yend)

    if steep then
        self:_plot(ypxl1,   xpxl1, rfpart(yend) * xgap)
        self:_plot(ypxl1+1, xpxl1,  fpart(yend) * xgap)
    else
        self:_plot(xpxl1, ypxl1  , rfpart(yend) * xgap)
        self:_plot(xpxl1, ypxl1+1,  fpart(yend) * xgap)
    end
    local intery = yend + gradient
    
    xend = round(x1)
    yend = y1 + gradient * (xend - x1)
    xgap = fpart(x1 + 0.5)
    local xpxl2 = xend
    local ypxl2 = ipart(yend)
    if steep then
        self:_plot(ypxl2  , xpxl2, rfpart(yend) * xgap)
        self:_plot(ypxl2+1, xpxl2,  fpart(yend) * xgap)
    else
        self:_plot(xpxl2, ypxl2,  rfpart(yend) * xgap)
        self:_plot(xpxl2, ypxl2+1, fpart(yend) * xgap)
    end
    
    if steep then
        for x = xpxl1 + 1, xpxl2 - 1 do
           self:_plot(ipart(intery)  , x, rfpart(intery))
           self:_plot(ipart(intery)+1, x,  fpart(intery))
           intery = intery + gradient
        end
    else
        for x = xpxl1 + 1, xpxl2 - 1 do
           self:_plot(x, ipart(intery),  rfpart(intery))
           self:_plot(x, ipart(intery)+1, fpart(intery))
           intery = intery + gradient
       end
    end 
end 

function DensityPlot:draw_segment(seg)
    local x0 = self.dpi * (seg.p0[1] - self.box.ll[1])
    local y0 = self.dpi * (seg.p0[2] - self.box.ll[2])
    local x1 = self.dpi * (seg.p1[1] - self.box.ll[1])
    local y1 = self.dpi * (seg.p1[2] - self.box.ll[2])
    self:_plot_line(x0, y0, x1, y1)
end

function DensityPlot:draw_point(p)
    local x = self.dpi * (p[1] - self.box.ll[1])
    local y = self.dpi * (p[2] - self.box.ll[2])
    self:_plot(x, y, 1)
end

function DensityPlot:image()
    return self.grid
end

function DensityPlot:size()
    return self.N[1] * self.N[2]
end

function DensityPlot:shape()
    return self.N
end

function DensityPlot:show()
    for j = self.N[2]-1, 0, -1 do
        for i = 0, self.N[1]-1 do
            local c = self.grid[i + j*self.N[1]]
            io.write(c == 0 and ' ' or '*')
        end
        io.write('\n')
    end
end

return {DensityPlot=DensityPlot}

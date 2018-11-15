local math = require('math')
local util = require('util')
local ffi = require('ffi')
local objects = require('objects')

ffi.cdef[[
    void *malloc(size_t size);
    size_t free(void*);
]]

function create_array(N)
    return ffi.gc(
        ffi.cast('double*', ffi.C.malloc(ffi.sizeof('double')*N)),
        ffi.C.free
    )
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
    self.grid = create_array(self.N[1] * self.N[2])
end

function DensityPlot:plot(x, y, c)

end

function DensityPlot:plot_line(x0, y0, x1, y1)
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
        plot(ypxl1,   xpxl1, rfpart(yend) * xgap)
        plot(ypxl1+1, xpxl1,  fpart(yend) * xgap)
    else
        plot(xpxl1, ypxl1  , rfpart(yend) * xgap)
        plot(xpxl1, ypxl1+1,  fpart(yend) * xgap)
    end
    local intery = yend + gradient
    
    xend = round(x1)
    yend = y1 + gradient * (xend - x1)
    xgap = fpart(x1 + 0.5)
    local xpxl2 = xend
    local ypxl2 = ipart(yend)
    if steep then
        plot(ypxl2  , xpxl2, rfpart(yend) * xgap)
        plot(ypxl2+1, xpxl2,  fpart(yend) * xgap)
    else
        plot(xpxl2, ypxl2,  rfpart(yend) * xgap)
        plot(xpxl2, ypxl2+1, fpart(yend) * xgap)
    end
    
    if steep then
        for x = xpxl1 + 1, xpxl2 - 1 do
           plot(ipart(intery)  , x, rfpart(intery))
           plot(ipart(intery)+1, x,  fpart(intery))
           intery = intery + gradient
        end
    else
        for x = xpxl1 + 1, xpxl2 - 1 do
           plot(x, ipart(intery),  rfpart(intery))
           plot(x, ipart(intery)+1, fpart(intery))
           intery = intery + gradient
       end
    end 
end 

d = DensityPlot(objects.Box({0, 0}, {1, 1}), 100)
d.grid[0] = 1

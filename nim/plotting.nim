import array2d
import image
import objects
import vector

import std/math

proc ipart*(x: float): float {.inline.} = return floor(x)
proc round*(x: float): float {.inline.} = return ipart(x + 0.5)
proc fpart*(x: float): float {.inline.} = return x - floor(x)
proc rfpart*(x: float): float {.inline.} = return 1 - fpart(x)

proc swap*(a: float, b: float): (float, float) = return (b, a)
proc swap*(a: int, b: int): (int, int) = return (b, a)

iterator `..`*(a: float, b: float, c: float): float =
  var res: float = a
  while res <= b:
    yield res
    res = res + c

proc inc(x: var float; y: float = 1.0) =
    x = x + y

# ========================================================
type
    DensityPlot* = ref object of RootObj
        box: Box
        dpi: float
        blendmode: BlendFunction
        grid*: Array2D[float]

proc initDensityPlot*(self: DensityPlot, box: Box, dpi: float, blendmode: BlendFunction): DensityPlot =
    self.box = box
    self.dpi = dpi
    let size: Vec = self.box.uu - self.box.ll
    let N: array[2, int] = [
        floor(self.dpi * size[0]).int,
        floor(self.dpi * size[1]).int
    ]
    self.grid = Array2D[float]()
    self.grid.initArray2D(N)
    self.blendmode = blendmode
    return self

proc reflect*(self: DensityPlot, y: float): float =
    return self.grid.shape[1].float - y - 1.0

proc plot*(self: DensityPlot, x: float, y: float, c: float): void {.discardable.} =
    if x < 0 or x >= self.grid.shape[0].float or y < 0 or y >= self.grid.shape[1].float:
        return

    let xi: int = floor(x).int
    let yi: int = floor(self.reflect(y)).int
    let ind = xi + yi*self.grid.shape[0]
    self.grid.data[ind] = self.blendmode(c, self.grid.data[ind])

proc plot_line*(self: DensityPlot, ix0: float, iy0: float, ix1: float, iy1: float): void {.discardable.} =
    var x0: float = ix0
    var y0: float = iy0
    var x1: float = ix1
    var y1: float = iy1
    let steep: bool = abs(y1 - y0) > abs(x1 - x0)
    
    if steep:
        (x0, y0) = swap(x0, y0)
        (x1, y1) = swap(x1, y1)
    if x0 > x1:
        (x0, x1) = swap(x0, x1)
        (y0, y1) = swap(y0, y1)
    
    let dx = x1 - x0
    let dy = y1 - y0
    var gradient: float = dy / dx
    if dx == 0:
        gradient = 1.0

    var xend: float = round(x0).float
    var yend: float = y0 + gradient * (xend - x0)
    var xgap: float = rfpart(x0 + 0.5)
    var xpxl1: float = xend
    var ypxl1: float = ipart(yend).float

    if steep:
        self.plot(ypxl1,   xpxl1, rfpart(yend) * xgap)
        self.plot(ypxl1+1, xpxl1,  fpart(yend) * xgap)
    else:
        self.plot(xpxl1, ypxl1  , rfpart(yend) * xgap)
        self.plot(xpxl1, ypxl1+1,  fpart(yend) * xgap)
    var intery = yend + gradient
    
    xend = round(x1)
    yend = y1 + gradient * (xend - x1)
    xgap = fpart(x1 + 0.5)
    var xpxl2 = xend
    var ypxl2 = ipart(yend)
    if steep:
        self.plot(ypxl2  , xpxl2, rfpart(yend) * xgap)
        self.plot(ypxl2+1, xpxl2,  fpart(yend) * xgap)
    else:
        self.plot(xpxl2, ypxl2,  rfpart(yend) * xgap)
        self.plot(xpxl2, ypxl2+1, fpart(yend) * xgap)
    
    if steep:
        for x in xpxl1 + 1 .. xpxl2 - 1:
           self.plot(ipart(intery)  , x, rfpart(intery))
           self.plot(ipart(intery)+1, x,  fpart(intery))
           intery = intery + gradient
    else:
        for x in xpxl1 + 1 .. xpxl2 - 1:
           self.plot(x, ipart(intery),  rfpart(intery))
           self.plot(x, ipart(intery)+1, fpart(intery))
           intery = intery + gradient

proc draw_segment*(self: DensityPlot, seg: Segment): void {.discardable.} =
    let ll = self.box.ll
    let uu = self.box.uu

    let x0 = (self.grid.shape[0].float * (seg.p0[0] - ll[0]) / (uu[0] - ll[0]))
    let y0 = (self.grid.shape[1].float * (seg.p0[1] - ll[1]) / (uu[1] - ll[1]))
    let x1 = (self.grid.shape[0].float * (seg.p1[0] - ll[0]) / (uu[0] - ll[0]))
    let y1 = (self.grid.shape[1].float * (seg.p1[1] - ll[1]) / (uu[1] - ll[1]))
    self.plot_line(x0, y0, x1, y1)

proc draw_point*(self: DensityPlot, p: Vec): void {.discardable.} =
    let x = (self.dpi * (p[0] - self.box.ll[0]))
    let y = (self.dpi * (p[1] - self.box.ll[1]))
    self.plot(x, y, 1.0)

proc get_array*(self: DensityPlot): Array2D[float] = return self.grid

proc show*(self: DensityPlot): void {.discardable.} =
    for j in countdown(self.grid.shape[2]-1, 0):
        for i in countup(0, self.grid.shape[1]-1):
            let c: int = self.grid.data[(i + j*self.grid.shape[1]).int].int
            if c == 0:
                stdout.write(" ")
            else:
                stdout.write("*")
        stdout.writeLine("")

{.warning[LockLevel]:off.}
import array2d
import image
import log
import objects
import plotting
import vector

import std/math
import std/streams
import std/strformat
import std/strutils
import std/tables

type
    Observer* = ref object of RootObj

method init*(self: Observer): void {.base.} = return
method begin*(self: Observer): void {.base.} = return
method set_particle*(self: Observer, particle: PointParticle): void {.base.} = return
method record_object*(self: Observer, obj: Object): void {.base.} = return
method update_particle*(self: Observer, particle: PointParticle): void {.base.} = return
method update_time*(self: Observer, time: float): void {.base.} = return
method update_step*(self: Observer, time: int): void {.base.} = return
method update_collision*(self: Observer, particle: PointParticle, obj: Object, time: float): void {.base.} = return
method is_triggered*(self: Observer): bool {.base.} = false
method is_triggered_particle*(self: Observer, particle: PointParticle): bool {.base.} = false
method reset*(self: Observer): void {.base.} = return
method close*(self: Observer): void {.base.} = return
method `$`*(self: Observer): string {.base.} = "Observer"

# =================================================================
type
    ObserverGroup* = ref object of Observer
        observers*: seq[Observer]

proc initObserverGroup*(self: ObserverGroup, observers: seq[Observer]): ObserverGroup =
    self.observers = observers
    return self

method begin*(self: ObserverGroup): void =
    for obs in self.observers:
        obs.begin()

method record_object*(self: ObserverGroup, obj: Object): void =
    for obs in self.observers:
        obs.record_object(obj)

method update_particle*(self: ObserverGroup, particle: PointParticle): void =
    for obs in self.observers:
        obs.update_particle(particle)

method update_time*(self: ObserverGroup, time: float): void =
    for obs in self.observers:
        obs.update_time(time)

method update_step*(self: ObserverGroup, time: int): void =
    for obs in self.observers:
        obs.update_step(time)

method update_collision*(self: ObserverGroup, particle: PointParticle, obj: Object, time: float): void =
    for obs in self.observers:
        obs.update_collision(particle, obj, time)

method is_triggered*(self: ObserverGroup): bool =
    for obs in self.observers:
        if obs.is_triggered():
            return true
    return false

method is_triggered_particle*(self: ObserverGroup, particle: PointParticle): bool =
    for obs in self.observers:
        if obs.is_triggered_particle(particle):
            return true
    return false

method reset*(self: ObserverGroup): void =
    for obs in self.observers:
        obs.reset()

method close*(self: ObserverGroup): void =
    for obs in self.observers:
        obs.close()

# =================================================================
type
    StepPrinter* = ref object of Observer
        interval*: int

proc initStepPrinter*(self: StepPrinter, interval: int = 1): StepPrinter =
    self.interval = interval
    return self

method update_step*(self: StepPrinter, t: int): void =
    if t mod self.interval == 0:
        echo fmt"Step: {t}"

method `$`*(self: StepPrinter): string =
    return fmt"StepPrinter: interval={self.interval}"

# =================================================================
type
    TimePrinter* = ref object of Observer
        interval*: float
        time*: float

proc initTimePrinter*(self: TimePrinter, interval: float = 1.0): TimePrinter =
    self.interval = interval
    return self

method begin*(self: TimePrinter): void =
    self.time = 0.0 

method update_time*(self: TimePrinter, t: float): void =
    let next = (1.0 + floor(self.time / self.interval)) * self.interval
    if self.time < next and t > next:
        echo fmt"{self.time}, {next}"
    self.time = t

method `$`*(self: TimePrinter): string =
    return fmt"TimePrinter: interval={self.interval}"

# =================================================================
type
    ImageRecorder* = ref object of Observer
        format*: string
        filename*: string
        plotter*: DensityPlot
        lastposition*: Table[int, Vec]
        cmap*: CmapFunction
        norm*: NormFunction

proc initImageRecorder*(
        self: ImageRecorder, 
        filename: string,
        plotter: DensityPlot,
        format: string = "pgm5", 
        cmap: CmapFunction,
        norm: NormFunction): ImageRecorder =
    self.format = format
    self.filename = filename
    self.plotter = plotter
    self.lastposition = initTable[int, Vec]()

    self.cmap = cmap
    self.norm = norm
    return self

method record_object*(self: ImageRecorder, obj: Object): void =
    var s = 1000
    for t in 0 .. s:
        var t0 = t.float / s.float
        var t1 = (t.float + 1.float) / s.float
        var s0 = Segment().initSegment(p0=obj.t(t0), p1=obj.t(t1))
        self.plotter.draw_segment(s0)

method update_particle*(self: ImageRecorder, particle: PointParticle): void =
   let ind = particle.index
   if self.lastposition.hasKey(ind):
       var lastposition = self.lastposition[ind]
       var segment = Segment().initSegment(lastposition, particle.pos)
       self.plotter.draw_segment(segment)
       self.lastposition[ind] = particle.pos
   else:
       self.lastposition[ind] = particle.pos

method update_collision*(self: ImageRecorder, particle: PointParticle, obj: Object, time: float): void = return
method reset*(self: ImageRecorder): void = self.lastposition = initTable[int, Vec]()

proc tone*(self: ImageRecorder): Array2D[uint8] = 
   let data = self.cmap(self.norm(self.plotter.grid.data))
   var arr = Array2D[uint8]()
   arr = arr.initArray2D(shape=self.plotter.grid.shape)
   arr.data = data
   return arr

proc `+`*(self: ImageRecorder, other: ImageRecorder): Observer =
    self.plotter.grid = self.plotter.grid + other.plotter.grid
    return self

method `$`*(self: ImageRecorder): string = 
    var o = "ImageRecorder: \n"
    o &= fmt"  filename='{self.filename}'" & "\n"
    o &= fmt"  format='{self.format}'" & "\n"
    o &= $self.plotter
    return o

type
    PeriodicImageRecorder* = ref object of ImageRecorder
        step_interval*: int
        step*: int
        saves*: int

proc initPeriodicImageRecorder*(
        self: PeriodicImageRecorder, 
        filename: string,
        plotter: DensityPlot,
        format: string = "pgm5", 
        cmap: CmapFunction,
        norm: NormFunction,
        step_interval: int): PeriodicImageRecorder =
    discard self.ImageRecorder.initImageRecorder(filename, plotter, format, cmap, norm)
    self.step_interval = step_interval
    self.step = 0
    self.saves = 0
    return self

# =================================================================
type
    PointImageRecorder* = ref object of ImageRecorder

method update_particle*(self: PointImageRecorder, particle: PointParticle): void = 
    self.plotter.draw_point(particle.pos)

# ========================================================
type
    SVGLinePlot* = ref object of Observer
        filename*: string
        buffer*: StringStream
        box: Box
        lw: float
        opacity: float
        crosspath: bool
        lastpt: Table[int, Vec]
        lastind: int
        breakpt: int
        y0, y1: float
        path_start*: string
        path_end*: string
        header*: string
        footer*: string
        count: int

const SVG_HEADER: string = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="$#in" height="$#in" viewBox="$# $# $# $#"
     style="background-color:white;"
><rect width="100%" height="100%" fill="white"/><g>
"""

const SVG_PATH_STR: string = """<path style="fill:none;stroke:#000000;stroke-width:$#in;stroke-opacity:$#" d=""""
const SVG_PATH_END: string = """"/>\n"""
# const SVG_PATH_RAW_STR: string = """d=""""
# const SVG_PATH_RAW_END: string = """"\n"""
const SVG_FOOTER: string = """</g></svg>"""

proc initSVGLinePlot*(self: SVGLinePlot, filename: string, box: Box, lw: float, opacity: float=1.0, crosspath: bool=false): SVGLinePlot =
    self.filename = filename
    self.box = box
    self.lw = lw
    self.opacity = opacity
    self.crosspath = crosspath
    self.lastpt = initTable[int, Vec]()
    self.lastind = -1
    self.breakpt = 10000
    self.y0 = self.box.ll[1]
    self.y1 = self.box.uu[1]
    self.path_start = SVG_PATH_STR
    self.path_end = SVG_PATH_END
    self.header = SVG_HEADER
    self.footer = SVG_FOOTER
    return self

method `$`*(self: SVGLinePlot): string = 
    var o = "SVGLinePlot:\n"
    o &= fmt"  box={$self.box}" & "\n"
    o &= fmt"  filename={$self.filename}" & "\n"
    o &= fmt"  lw={$self.lw}"
    return o

method begin*(self: SVGLinePlot): void =
    self.count = 0
    self.buffer = newStringStream()
    self.buffer.write(
        self.header % [
        $(self.box.uu[0] - self.box.ll[0]),
        $(self.box.uu[1] - self.box.ll[1]),
            $self.box.ll[0], $self.box.ll[1],
            $self.box.uu[0], $self.box.uu[1]]
    )

proc reflect*(self: SVGLinePlot, p: Vec): Vec =
    return [p[0], (self.y1 - p[1]) + self.y0]

method update_particle*(self: SVGLinePlot, particle: PointParticle): void =
    let ind = particle.index
    let pos = self.reflect(particle.pos)

    var pt: Vec
    let lind = self.lastind
    if self.lastpt.hasKey(ind):
        let lpos = self.lastpt[ind]
        pt = lpos
    else:
        pt = pos

    if self.count == 0:
        self.buffer.write(self.path_start % [$self.lw, $self.opacity])
        self.buffer.write(fmt"M{pt[0]},{pt[1]} "&"\n")
    else:
        if self.crosspath or (lind == ind):
            self.buffer.write(fmt"L{pos[0]},{pos[1]} "&"\n")
        else:
            self.buffer.write(fmt"M{pt[0]},{pt[1]} "&"\n")
            self.buffer.write(fmt"L{pos[0]},{pos[1]} "&"\n")

    self.lastpt[ind] = pos
    self.lastind = ind
    self.count = self.count + 1

    if self.count > self.breakpt:
        self.buffer.write(self.path_end)
        self.count = 0
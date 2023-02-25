{.warning[LockLevel]:off.}
import array2d
import image
import objects
import plotting
import vector

import std/streams
import std/strformat
import std/strutils
import std/tables

type
    Observer* = ref object of RootObj

method init*(self: Observer): void {.base.} = return
method begin*(self: Observer): void {.base.} = return
method set_particle*(self: Observer, particle: PointParticle): void {.base.} = return
method update_particle*(self: Observer, particle: PointParticle): void {.base.} = return
method update_time*(self: Observer, time: float): void {.base.} = return
method update_collision*(self: Observer, particle: PointParticle, obj: Object, time: float): void {.base.} = return
method is_triggered*(self: Observer): bool {.base.} = false
method is_triggered_particle*(self: Observer, particle: PointParticle): bool {.base.} = false
method reset*(self: Observer): void {.base.} = return
method close*(self: Observer): void {.base.} = return
method `$`*(self: Observer): string {.base.} = "Observer"

# =================================================================
type
    StateFileRecorder* = ref object of Observer
        filename*: string
        file*: File

proc initStateFileRecorder*(self: StateFileRecorder, filename: string): StateFileRecorder = 
    self.filename = filename
    return self

method begin*(self: StateFileRecorder): void =
    self.file = open(self.filename, fmWrite)

method update_particle*(self: StateFileRecorder, particle: PointParticle): void =
    let pos = particle.pos
    let vel = particle.vel
    let acc = particle.acc
    self.file.writeLine(
        fmt"{pos[0]} {pos[1]} {vel[0]} {vel[1]} {acc[0]} {acc[1]}\n"
    )

method close*(self: StateFileRecorder): void =
    self.file.close()

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

proc save_csv*(self: ImageRecorder): void = self.plotter.grid.save_csv(self.filename)
proc save_bin*(self: ImageRecorder): void = self.plotter.grid.save_bin(self.filename)
proc save_pgm2*(self: ImageRecorder): void = self.tone().save_pgm2(self.filename)
proc save_pgm5*(self: ImageRecorder): void = self.tone().save_pgm5(self.filename)

method close*(self: ImageRecorder): void =
    if self.format == "bin":
        self.save_bin()
    if self.format == "csv":
        self.save_csv()
    if self.format == "pgm2":
        self.save_pgm2()
    if self.format == "pgm5":
        self.save_pgm5()

method `$`*(self: ImageRecorder): string = 
    var o = "ImageRecorder: \n"
    o &= fmt"  filename='{self.filename}'" & "\n"
    o &= fmt"  format='{self.format}'" & "\n"
    o &= $self.plotter
    return o

# =================================================================
type
    PointImageRecorder* = ref object of ImageRecorder

method update_particle*(self: PointImageRecorder, particle: PointParticle): void = 
    self.plotter.draw_point(particle.pos)

# ========================================================
type
    SVGLinePlot* = ref object of Observer
        filename: string
        file: File
        buffer: StringStream
        box: Box
        lw: float
        opacity: float
        crosspath: bool
        lastpt: Table[int, Vec]
        lastind: int
        breakpt: int
        y0, y1: float
        path_start: string
        path_end: string
        header: string
        footer: string
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
    return fmt"SVGLinePlot: {$self.filename} {$self.box} {$self.lw}"

method begin*(self: SVGLinePlot): void =
    self.count = 0
    self.file = open(self.filename, fmWrite)
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
        self.buffer.write(fmt"M{pt[0]},{pt[1]} ")
    else:
        if self.crosspath or (lind == ind):
            self.buffer.write(fmt"L{pos[0]},{pos[1]} ")
        else:
            self.buffer.write(fmt"M{pt[0]},{pt[1]} ")
            self.buffer.write(fmt"L{pos[0]},{pos[1]} ")

    self.lastpt[ind] = pos
    self.lastind = ind
    self.count = self.count + 1

    if self.count > self.breakpt:
        self.buffer.write(self.path_end)
        self.count = 0

method close*(self: SVGLinePlot): void =
    self.buffer.write(self.path_end)
    self.buffer.write(self.footer)
    self.file.write(self.buffer.data)

# =================================================================
type
    InitialStateRecorder* = ref object of Observer
        filename*: string
        particles*: Table[int, PointParticle]

proc initInitialStateRecorder*(self: InitialStateRecorder, filename: string): InitialStateRecorder =
    self.filename = filename
    self.particles = initTable[int, PointParticle]()
    return self

method update_particle*(self: InitialStateRecorder, particle: PointParticle): void =
    let i = particle.index
    if not self.particles.hasKey(i):
        self.particles[i] = particle

method close*(self: InitialStateRecorder): void =
    var file = open(self.filename, fmWrite)

    for i, p in self.particles:
        file.write(fmt"{p.pos[0]}, {p.pos[1]}, {p.vel[0]}, {p.vel[1]}, {p.acc[0]}, {p.acc[1]}\n")

    file.close()

# =================================================================
type
    LastStateRecorder* = ref object of Observer
        filename*: string
        particles*: Table[int, PointParticle]

proc initLastStateRecorder*(self: LastStateRecorder, filename: string): LastStateRecorder =
    self.filename = filename
    self.particles = initTable[int, PointParticle]()
    return self

method update_particle*(self: LastStateRecorder, particle: PointParticle): void =
    let i = particle.index
    self.particles[i] = particle

method close*(self: LastStateRecorder): void =
    let file = open(self.filename, fmWrite)

    for i, p in self.particles:
        file.write(fmt"{p.pos[0]}, {p.pos[1]}, {p.vel[0]}, {p.vel[1]}, {p.acc[0]}, {p.acc[1]}\n")

    file.close()

#[
-- =================================================================
local LastCollisionRecorder = util.class(Observer)
function LastCollisionRecorder:init(filename)
    self.filename = filename
    self.object_index = {}
end

function LastCollisionRecorder:update_collision(particle, object, time)
    local i = particle.index
    self.object_index[i] = object.obj_index
end

function LastCollisionRecorder:close()
    local file = io.open(self.filename, 'w')
    for i = 1, #self.object_index do
        file:write(
            string.format('%d\n', self.object_index[i])
        )
    end
    file:flush()
    file:close()
end

-- =================================================================
local CollisionCountRecorder = util.class(Observer)
function CollisionCountRecorder:init(filename)
    self.filename = filename
    self.bounces = {}
end

function CollisionCountRecorder:update_collision(particle, object, time)
    local i = particle.index

    if self.bounces[i] == nil then
        self.bounces[i] = 0
    end
    self.bounces[i] = self.bounces[i] + 1
end

function CollisionCountRecorder:close()
    local file = io.open(self.filename, 'w')
    for i = 1, #self.bounces do
        file:write(
            string.format('%d\n', self.bounces[i])
        )
    end
    file:flush()
    file:close()
end
]#

# =================================================================
type
    TimePrinter* = ref object of Observer
        interval: int
        step: int

proc initTimePrinter*(self: TimePrinter, interval: int = 100000): TimePrinter =
    self.interval = interval
    return self

method begin*(self: TimePrinter): void =
    self.step = 0

method update_time*(self: TimePrinter, t: float): void =
    if self.step mod self.interval == 0:
        stdout.writeLine($self.step)

    self.step = self.step + t.int

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

method update_particle*(self: ObserverGroup, particle: PointParticle): void =
    for obs in self.observers:
        obs.update_particle(particle)

method update_time*(self: ObserverGroup, time: float): void =
    for obs in self.observers:
        obs.update_time(time)

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

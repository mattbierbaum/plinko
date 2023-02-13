import image
import objects
import plotting
import vector

import std/strformat
import std/strutils
import std/tables

type
    Observer = ref object of RootObj

proc init*(self: Observer): void {.discardable.} = return
proc begin*(self: Observer): void {.discardable.} = return
proc set_particle*(self: Observer, particle: PointParticle): void {.discardable.} = return
proc update_particle*(self: Observer, particle: PointParticle): void {.discardable.} = return
proc update_time*(self: Observer, time: float): void {.discardable.} = return
proc update_collision*(self: Observer, particle: PointParticle, obj: Object, time: float): void {.discardable.} = return
proc is_triggered*(self: Observer): bool {.discardable.} = false
proc is_triggered_particle*(self: Observer, particle: PointParticle): bool {.discardable.} = false
proc reset*(self: Observer): void {.discardable.} = return
proc close*(self: Observer): void {.discardable.} = return

# =================================================================
type
    StateFileRecorder = ref object of Observer
        filename*: string
        file*: File

proc initStateFileRecorder*(self: StateFileRecorder, filename: string): StateFileRecorder = 
    self.filename = filename
    return self

proc being*(self: StateFileRecorder): void =
    self.file = open(self.filename, fmWrite)

proc update_particle*(self: StateFileRecorder, particle: PointParticle): void =
    let pos = particle.pos
    let vel = particle.vel
    let acc = particle.acc
    self.file.writeLine(
        fmt"{pos[0]} {pos[1]} {vel[0]} {vel[1]} {acc[0]} {acc[1]}\n"
    )

proc close*(self: StateFileRecorder): void =
    self.file.close()

# =================================================================
type
    ImageRecorder = ref object of Observer
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
        norm: NormFunction,
        ): ImageRecorder =
    self.format = format
    self.filename = filename
    self.plotter = plotter
    self.lastposition = initTable[int, Vec]()

    self.cmap = cmap
    self.norm = norm
    return self

    #if toner ~= nil then
    #    self.cmap = toner.cmap ~= nil and toner.cmap or self.cmap
    #    self.norm = toner.norm ~= nil and toner.norm or self.norm
    #end

proc begin*(self: ImageRecorder): void = return

proc update_particle*(self: ImageRecorder, particle: PointParticle): void =
    let ind = particle.index

    if not self.lastposition.hasKey(ind):
        var lastposition = self.lastposition[ind]
        var segment = Segment().initSegment(lastposition, particle.pos)
        self.plotter.draw_segment(segment)
        self.lastposition[ind] = particle.pos
    else:
        self.lastposition[ind] = particle.pos

proc update_collision*(self: ImageRecorder, particle: PointParticle, obj: Object, time: float): void = return
proc reset*(self: ImageRecorder): void = self.lastposition = initTable[int, Vec]()
proc tone*(self: ImageRecorder): seq[uint8] = return self.cmap(self.norm(self.plotter.get_array()))
# proc save_csv*(self: ImageRecorder): void =  self.plotter.get_array().save_csv(self.filename)
# proc save_bin*(self: ImageRecorder): void = self.plotter.get_array().save_bin(self.filename)
# proc save_pgm2*(self: ImageRecorder): void = self.tone().save_pgm2(self.filename)
# proc save_pgm5*(self: ImageRecorder): void = self.tone().save_pgm5(self.filename)
# proc save_ppm*(self: ImageRecorder): void = self.tone().save_ppm(self.filename)

proc close*(self: ImageRecorder): void =
    return
    # if self.format == "csv":
    #     self.save_csv()
    # if self.format == "bin":
    #     self.save_bin()
    # if self.format == "pgm5":
    #     self.save_pgm5()

# =================================================================
type
    PointImageRecorder = ref object of ImageRecorder

proc initPointImageRecorder*(self: PointImageRecorder, filename: string, plotter: DensityPlot): PointImageRecorder =
    #discard self.initImageRecorder(filename, plotter)
    return self

proc update_particle*(self: PointImageRecorder, particle: PointParticle): void = self.plotter.draw_point(particle.pos)

# ========================================================
type
    SVGLinePlot = ref object of Observer
        filename: string
        file: File
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

proc begin*(self: SVGLinePlot): void =
    self.count = 0
    self.file = open(self.filename, fmWrite)
    self.file.write(
        self.header % [
        $(self.box.uu[1] - self.box.ll[1]),
        $(self.box.uu[2] - self.box.ll[2]),
            $self.box.ll[0], $self.box.ll[1],
            $self.box.uu[0], $self.box.uu[1]]
    )

proc reflect*(self: SVGLinePlot, p: Vec): Vec =
    return [p[0], (self.y1 - p[1]) + self.y0]

proc update_particle*(self: SVGLinePlot, particle: PointParticle): void =
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
        self.file.write(self.path_start % [$self.lw, $self.opacity])
        self.file.write(fmt"M{pt[0]},{pt[1]} ")
    else:
        if self.crosspath or (lind == ind):
            self.file.write(fmt"L{pos[0]},{pos[1]} ")
        else:
            self.file.write(fmt"M{pt[0]},{pt[1]} ")
            self.file.write(fmt"L{pos[0]},{pos[1]} ")

    self.lastpt[ind] = pos
    self.lastind = ind
    self.count = self.count + 1

    if self.count > self.breakpt:
        self.file.write(self.path_end)
        self.count = 0

proc close*(self: SVGLinePlot): void =
    self.file.write(self.path_end)
    self.file.write(self.footer)
    self.file.close()

# =================================================================
type
    InitialStateRecorder = ref object of Observer
        filename*: string
        particles*: Table[int, PointParticle]

proc initInitialStateRecorder*(self: InitialStateRecorder, filename: string): InitialStateRecorder =
    self.filename = filename
    self.particles = initTable[int, PointParticle]()
    return self

proc update_particle*(self: InitialStateRecorder, particle: PointParticle): void =
    let i = particle.index
    if not self.particles.hasKey(i):
        self.particles[i] = particle

proc close*(self: InitialStateRecorder): void =
    var file = open(self.filename, fmWrite)

    for i, p in self.particles:
        file.write(fmt"{p.pos[0]}, {p.pos[1]}, {p.vel[0]}, {p.vel[1]}, {p.acc[0]}, {p.acc[1]}\n")

    file.close()

# =================================================================
type
    LastStateRecorder = ref object of Observer
        filename*: string
        particles*: Table[int, PointParticle]

proc initLastStateRecorder*(self: LastStateRecorder, filename: string): LastStateRecorder =
    self.filename = filename
    self.particles = initTable[int, PointParticle]()
    return self

proc update_particle*(self: LastStateRecorder, particle: PointParticle): void =
    let i = particle.index
    self.particles[i] = particle

proc close*(self: LastStateRecorder): void =
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
    TimePrinter = ref object of Observer
        interval: int
        step: int

proc initTimePrinter*(self: TimePrinter, interval: int = 100000): TimePrinter =
    self.interval = interval
    return self

proc begin*(self: TimePrinter): void =
    self.step = 0

proc update_time*(self: TimePrinter, t: float): void =
    if self.step mod self.interval == 0:
        stdout.writeLine($self.step)

    self.step = self.step + 1

# =================================================================
type
    ObserverGroup* = ref object of Observer
        observers*: seq[Observer]

proc initObserverGroup*(self: ObserverGroup, observers: seq[Observer]): ObserverGroup =
    self.observers = observers
    return self

proc begin*(self: ObserverGroup): void =
    for obs in self.observers:
        obs.begin()

proc update_particle*(self: ObserverGroup, particle: PointParticle): void =
    for obs in self.observers:
        obs.update_particle(particle)

proc update_time*(self: ObserverGroup, time: float): void =
    for obs in self.observers:
        obs.update_time(time)

proc update_collision*(self: ObserverGroup, particle: PointParticle, obj: Object, time: float): void =
    for obs in self.observers:
        obs.update_collision(particle, obj, time)

proc is_triggered*(self: ObserverGroup): bool =
    for obs in self.observers:
        if obs.is_triggered():
            return true
    return false

proc is_triggered_particle*(self: ObserverGroup, particle: PointParticle): bool =
    for obs in self.observers:
        if obs.is_triggered_particle(particle):
            return true
    return false

proc reset*(self: ObserverGroup): void =
    for obs in self.observers:
        obs.reset()

proc close*(self: ObserverGroup): void =
    for obs in self.observers:
        obs.close()

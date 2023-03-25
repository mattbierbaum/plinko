{.warning[LockLevel]:off.}
import array2d
import objects
import observers
import particles
import plotting
import util
import vector

import std/os
import std/streams
import std/strformat
import std/tables

proc save_csv*[T](self: Array2D[T], filename: string,
        mode: string = "w"): void =
    var file: File
    if mode == "a":
        file = open(filename, fmAppend)
        file.setFilePos(0, fspEnd)
    else:
        file = open(filename, fmWrite)

    for j in 0 .. self.shape[1]-1:
        for i in 0 .. self.shape[0]-1:
            file.write(fmt"{self.data[i+j*self.shape[0]]} ")
        file.write("\n")
    file.close()

proc save_bin*[T](self: Array2D[T], filename: string, mode: string = "w"): void =
    let filesize:int = getFileSize(filename).int
    var file: FileStream
    if mode == "a":
        file = newFileStream(filename, fmAppend)
        file.setPosition(filesize)
    else:
        file = newFileStream(filename, fmWrite)

    for j in 0 .. self.shape[1]-1:
        for i in 0 .. self.shape[0]-1:
            file.write(self.data[i+j*self.shape[0]])
    file.close()

proc save_pgm2*(self: Array2D[uint8], filename: string): void =
    let file = open(filename, fmWrite)
    file.write(fmt"P2 {self.shape[1]} {self.shape[0]} 255" & "\n")
    file.close()

    self.save_csv(filename, "a")

proc save_pgm5*(self: Array2D[uint8], filename: string): void =
    let file = open(filename, fmWrite)
    file.write(fmt"P5 {self.shape[0]} {self.shape[1]} 255" & "\n")
    file.close()

    self.save_bin(filename, "a")

proc save_bin*[T: int|float](self: seq[T], filename: string, mode: string = "w"): void =
    if not fileExists(filename):
        let f = open(filename, fmWrite)
        f.close()

    let filesize:int = getFileSize(filename).int
    var file: FileStream
    if mode == "a":
        file = newFileStream(filename, fmAppend)
        file.setPosition(filesize)
    else:
        file = newFileStream(filename, fmWrite)

    for i in 0 .. self.len-1:
        file.write(self[i])
    file.close()

proc save_bin*(self: seq[Vec], filename: string, mode: string = "w"): void =
    if not fileExists(filename):
        let f = open(filename, fmWrite)
        f.close()

    let filesize:int = getFileSize(filename).int
    var file: FileStream
    if mode == "a":
        file = newFileStream(filename, fmAppend)
        file.setPosition(filesize)
    else:
        file = newFileStream(filename, fmWrite)

    for i in 0 .. self.len-1:
        for v in self[i]:
            file.write(v)
    file.close()

proc save_bin*[T: int|float|Vec](self: Table[int, T], filename: string): void =
    var L = 0
    for index, value in self:
        if index >= L:
            L = index
    var c: seq[T] = newSeq[T](L+1)
    for index, value in self:
        c[index] = value
    c.save_bin(filename)

proc save_bin*[T: int|float|Vec](self: Pmt[T], filename: string): void =
    self.value.save_bin(filename)

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
    NativeImageRecorder* = ref object of ImageRecorder

proc save_csv*(self: NativeImageRecorder): void = self.plotter.grid.save_csv(self.filename)
proc save_bin*(self: NativeImageRecorder): void = self.plotter.grid.save_bin(self.filename)
proc save_pgm2*(self: NativeImageRecorder): void = self.tone().save_pgm2(self.filename)
proc save_pgm5*(self: NativeImageRecorder): void = self.tone().save_pgm5(self.filename)

method close*(self: NativeImageRecorder): void =
    if self.format == "bin":
        self.save_bin()
    if self.format == "csv":
        self.save_csv()
    if self.format == "pgm2":
        self.save_pgm2()
    if self.format == "pgm5":
        self.save_pgm5()

proc `+`*(self: NativeImageRecorder, other: NativeImageRecorder): Observer =
    self.plotter.grid = self.plotter.grid + other.plotter.grid
    return self

# =================================================================
type
    NativePeriodicImageRecorder* = ref object of PeriodicImageRecorder

proc write_metadata*(self: NativePeriodicImageRecorder): void =
    var file = open(self.filename & "-shape.csv", fmWrite)
    file.write(fmt"{self.plotter.grid.shape[0]}, {self.plotter.grid.shape[1]}, {self.saves}")
    file.close()

method update_step*(self: NativePeriodicImageRecorder, step: int): void =
    self.step += 1
    if self.step.int mod self.step_interval.int == 0:
        self.saves += 1
        if self.saves == 1:
            self.plotter.grid.save_bin(self.filename, "w")
        else:
            self.plotter.grid.save_bin(self.filename, "a")
        self.write_metadata()

# =================================================================
type
    NativeSVGLinePlot* = ref object of SVGLinePlot

method close*(self: NativeSVGLinePlot): void =
    self.buffer.write(self.path_end)
    self.buffer.write(self.footer)
    var file = open(self.filename, fmWrite)
    file.write(self.buffer.data)

# TODO: use an intermediate table to generate the joint set.
proc join*[T](s0, s1: seq[T], f0, f1: seq[bool]): seq[T] =
    var o = newSeq[T](max(s0.len, s1.len))
    for i in 0 .. s0.len-1:
        o[i] = s0[i]
    for i in 0 .. o.len-1:
        if i < f1.len and f1[i]:
            o[i] = s1[i]
    return o

# =================================================================
type
    NativeCollisionCounter * = ref object of CollisionCounter

proc initNativeCollisionCounter*(self: NativeCollisionCounter, filename: string, obj: Object=nil): NativeCollisionCounter =
    discard self.CollisionCounter.initCollisionCounter(obj, filename)
    return self

method close*(self: NativeCollisionCounter): void =
    self.collisions.save_bin(self.filename)

proc `+`*(self: NativeCollisionCounter, other: NativeCollisionCounter): Observer =
    self.collisions = self.collisions.join(other.collisions)
    return self

# =================================================================
type
    NativeStopWatch* = ref object of StopWatch

proc initNativeStopWatch*(self: NativeStopWatch, filename: string): NativeStopWatch =
    discard self.StopWatch.initStopWatch(filename=filename)
    return self

method close*(self: NativeStopWatch): void =
    self.time.save_bin(self.filename)

proc `+`*(self: NativeStopWatch, other: NativeStopWatch): Observer =
    self.time = self.time.join(other.time)
    return self

# =================================================================
type
    NativeLastStateRecorder* = ref object of LastStateRecorder

proc initNativeLastStateRecorder*(self: NativeLastStateRecorder, filename: string): NativeLastStateRecorder =
    discard self.LastStateRecorder.initLastStateRecorder(filename=filename)
    return self

method close*(self: NativeLastStateRecorder): void =
    self.pos.save_bin(fmt"{self.filename}.pos")
    self.vel.save_bin(fmt"{self.filename}.vel")

proc `+`*(self: NativeLastStateRecorder, other: NativeLastStateRecorder): Observer =
    self.pos = self.pos.join(other.pos)
    self.vel = self.vel.join(other.vel)
    return self

# =================================================================
type
    NativeLastCollisionRecorder* = ref object of LastCollisionRecorder

proc initNativeLastCollisionRecorder*(self: NativeLastCollisionRecorder, filename: string): NativeLastCollisionRecorder =
    discard self.LastCollisionRecorder.initLastCollisionRecorder(filename=filename)
    return self

method close*(self: NativeLastCollisionRecorder): void =
    self.obj.save_bin(self.filename)

proc `+`*(self: NativeLastCollisionRecorder, other: NativeLastCollisionRecorder): Observer =
    for index, value in other.obj:
        self.obj[index] = value 
    return self

proc combine*(self: ObserverGroup, other: ObserverGroup): ObserverGroup =
    for i, obs0 in self.observers:
        for j, obs1 in other.observers:
            if obs0 of NativeCollisionCounter and obs1 of NativeCollisionCounter:
                self.observers[i] = obs0.NativeCollisionCounter + obs1.NativeCollisionCounter
            if obs0 of NativeImageRecorder and obs1 of NativeImageRecorder:
                self.observers[i] = obs0.NativeImageRecorder + obs1.NativeImageRecorder
            if obs0 of NativeStopWatch and obs1 of NativeStopWatch:
                self.observers[i] = obs0.NativeStopWatch + obs1.NativeStopWatch
            if obs0 of NativeLastStateRecorder and obs1 of NativeLastStateRecorder:
                self.observers[i] = obs0.NativeLastStateRecorder + obs1.NativeLastStateRecorder
            if obs0 of NativeLastCollisionRecorder and obs1 of NativeLastCollisionRecorder:
                self.observers[i] = obs0.NativeLastCollisionRecorder + obs1.NativeLastCollisionRecorder
    return self
{.warning[LockLevel]:off.}
import array2d
import objects
import observers
import plotting

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

# =================================================================
type
    NativeImageRecorder* = ref object of ImageRecorder

proc save_csv*(self: NativeImageRecorder): void = self.plotter.grid.save_csv(self.filename)
proc save_bin*(self: NativeImageRecorder): void = self.plotter.grid.save_bin(self.filename)
proc save_pgm2*(self: NativeImageRecorder): void = self.tone().save_pgm2(self.filename)
proc save_pgm5*(self: NativeImageRecorder): void = self.tone().save_pgm5(self.filename)

method duplicate*(self: NativeImageRecorder): Observer =
    return NativeImageRecorder().initImageRecorder(
        self.filename, self.plotter.duplicate(), self.format, self.cmap, self.norm)

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
    NativeSVGLinePlot* = ref object of SVGLinePlot

method close*(self: NativeSVGLinePlot): void =
    self.buffer.write(self.path_end)
    self.buffer.write(self.footer)
    var file = open(self.filename, fmWrite)
    file.write(self.buffer.data)
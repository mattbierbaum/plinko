import util
import vector

import std/math
import std/random
import std/strformat
import std/strutils

# -------------------------------------------------------------
type
    PointParticle* = object
        pos*, vel*, acc*: Vec
        time*: float
        active*: bool
        index*: int

type ParticleIterator* = iterator(): PointParticle

proc initPointParticle*(
        self: var PointParticle,
        pos: Vec = [0.0, 0.0], 
        vel: Vec = [0.0, 0.0], 
        acc: Vec = [0.0, 0.0],
        index: int = 0): PointParticle =
    self.pos = pos
    self.vel = vel
    self.acc = acc
    self.time = 0
    self.active = true
    self.index = index
    return self

proc copy*(self: var PointParticle, other: PointParticle): PointParticle {.discardable.} =
    self.pos = other.pos
    self.vel = other.vel
    self.acc = other.acc
    self.time = other.time
    self.index = other.index
    self.active = other.active
    return self

proc `$`*(self: PointParticle): string = fmt"Particle[{self.index}] <pos={$self.pos} vel={$self.vel}>"

# -------------------------------------------------------------
type
    ParticleGroup* = ref object of RootObj

method index*(self: ParticleGroup, index: int): PointParticle {.base.} = result
method count*(self: ParticleGroup): int {.base.} = result
method copy*(self: ParticleGroup, index: int, p: PointParticle): void {.base.} = return
method set_indices*(self: ParticleGroup, ind: int): int {.base.} = return ind
method `$`*(self: ParticleGroup): string {.base.} = ""
method partition*(self: ParticleGroup, num: int): seq[ParticleGroup] {.base.} = 
    var parts = newSeq[ParticleGroup](num)
    parts[0] = self
    return parts

# -------------------------------------------------------------
type
    SingleParticle* = ref object of ParticleGroup
        particle*: PointParticle
        particles*: seq[PointParticle]

proc initSingleParticle*(self: SingleParticle, particle: PointParticle): SingleParticle = 
    self.particles = @[particle]
    return self

method index*(self: SingleParticle, index: int): PointParticle = 
    if index == 0:
        return self.particles[0]

method count*(self: SingleParticle): int = 1
method copy*(self: SingleParticle, index: int, p: PointParticle): void = self.particles[0].copy(p)

method set_indices*(self: SingleParticle, ind: int): int =
    self.particles[0].index = ind
    return ind + 1

method `$`*(self: SingleParticle): string = return fmt"SingleParticle: {$self.particle}"

# -------------------------------------------------------------
type
    ParticleList* = ref object of ParticleGroup
        particles*: seq[PointParticle]

proc initParticleList*(self: ParticleList, particles: seq[PointParticle]): ParticleList = 
    self.particles = particles
    return self

method index*(self: ParticleList, index: int): PointParticle = result = self.particles[index]
method count*(self: ParticleList): int = len(self.particles)
method copy*(self: ParticleList, index: int, p: PointParticle): void = self.particles[index].copy(p)

method set_indices*(self: ParticleList, ind: int): int =
    var tmp_index = ind
    for i in 0 .. self.particles.len-1:#particle in self.particles:
        self.particles[i].index = tmp_index
        tmp_index += 1
    return tmp_index

method `$`*(self: ParticleList): string =
    var o = "ParticleList: \n"
    for particle in self.particles:
        o &= indent($particle)
    return o.strip()

method partition*(self: ParticleList, total: int): seq[ParticleGroup] =
    let size = (self.count() div total)
    var list: seq[ParticleGroup] = @[]
    for i in 0 .. total-1:
        var particles: seq[PointParticle] = @[]
        for ind in i*size .. (i+1)*size-1:
            particles.add(self.particles[ind])
        list.add(ParticleList().initParticleList(particles))
    return list

# -------------------------------------------------------------
type 
    UniformParticles* = ref object of ParticleList

proc initUniformParticles*(self: UniformParticles, p0: Vec, p1: Vec, v0: Vec, v1: Vec, N: int): UniformParticles =
    self.particles = newSeq[PointParticle](N)
    var p = PointParticle()
    for i in 0 .. N - 1:
        let f: float = i / (N - 1)
        let pos = lerp(p0, p1, f)
        let vel = lerp(v0, v1, f)
        self.particles[i].copy(p.initPointParticle(pos, vel, [0.0, 0.0]))
    return self

# -------------------------------------------------------------
type 
    RadialUniformParticles* = ref object of ParticleList

proc initRadialUniformParticles*(self: RadialUniformParticles, pos: Vec, v: float, a: array[2, float], N: int): RadialUniformParticles =
    self.particles = newSeq[PointParticle](N)
    var p = PointParticle()
    for i in 0 .. N - 1:
        var f: float = i / (N - 1)
        var a = PI * (f * (a[1] - a[0]) + a[0])
        let vel = [v * math.sin(a), v * math.cos(a)]
        self.particles[i].copy(p.initPointParticle(pos, vel, [0.0, 0.0]))
    return self

# -------------------------------------------------------------
type 
    UniformParticles2D* = ref object of ParticleList

proc initUniformParticles2D*(self: UniformParticles2D, p0: Vec, p1: Vec, v0: Vec, v1: Vec, N: array[2, int]): UniformParticles2D =
    let Nx = N[0]
    let Ny = N[1]
    let N = Nx * Ny

    self.particles = newSeq[PointParticle](N)
    var p = PointParticle()
    for i in 0 .. N - 1:
        let fx = (i mod Nx).float / (Nx.float-1)
        let fy = (i div Nx).float / (Ny.float-1)
        let fv: Vec = [fx.float, fy.float]

        let pos = vlerp(p0, p1, fv)
        let vel = vlerp(v0, v1, fv)
        self.particles[i].copy(p.initPointParticle(pos, vel, [0.0, 0.0]))
    return self

# -------------------------------------------------------------
type 
    UniformRandomParticles* = ref object of ParticleList

proc initUniformRandomParticles*(self: UniformRandomParticles, p0: Vec, p1: Vec, v0: Vec, v1: Vec, N: int): UniformRandomParticles =
    self.particles = newSeq[PointParticle](N)
    var p = PointParticle()
    for i in 0 .. N - 1:
        let f: float = rand(1.0)
        let pos = lerp(p0, p1, f)
        let vel = lerp(v0, v1, f)
        self.particles[i].copy(p.initPointParticle(pos, vel, [0.0, 0.0]))
    return self

# -------------------------------------------------------------
type 
    UniformRandomParticles2D* = ref object of ParticleList

proc initUniformRandomParticles2D*(self: UniformRandomParticles2D, p0: Vec, p1: Vec, v0: Vec, v1: Vec, N: array[2, int]): UniformRandomParticles2D =
    let Nx = N[0]
    let Ny = N[1]
    let N = Nx * Ny

    self.particles = newSeq[PointParticle](N)
    var p = PointParticle()
    for i in 0 .. N - 1:
        let fx = rand(1.0)
        let fy = rand(1.0)
        let fv: Vec = [fx.float, fy.float]

        let pos = vlerp(p0, p1, fv)
        let vel = vlerp(v0, v1, fv)
        self.particles[i].copy(p.initPointParticle(pos, vel, [0.0, 0.0]))
    return self
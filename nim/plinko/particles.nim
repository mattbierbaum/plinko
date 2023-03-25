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

method count*(self: ParticleGroup): int {.base.} = return 0
method index*(self: ParticleGroup, index: int): PointParticle {.base.} = result
method copy*(self: ParticleGroup, index: int, p: PointParticle): void {.base.} = return
method `$`*(self: ParticleGroup): string {.base.} = ""
method partition*(self: ParticleGroup, index: int, num: int): void {.base.} = return
method generate*(self: ParticleGroup, offset: int): int {.base.} = return

# -------------------------------------------------------------
type
    ParticleList* = ref object of ParticleGroup
        particles*: seq[PointParticle]
        p_count*: int  # Num of partitions
        p_index*: int  # Partition index
        p_size*: int  # Number of particles in the partition
        N*: int  # Number of total particles in the group

proc initParticleList*(self: ParticleList, N: int): ParticleList = 
    self.N = N
    self.particles = @[]
    return self

method create*(self: ParticleList, index: int): PointParticle {.base.} =
    return PointParticle()

method count*(self: ParticleList): int = self.p_size
method index*(self: ParticleList, index: int): PointParticle = return self.particles[index]
method copy*(self: ParticleList, index: int, p: PointParticle): void = self.particles[index].copy(p)

method `$`*(self: ParticleList): string =
    var o = "ParticleList: \n"
    for particle in self.particles:
        o &= indent($particle)
    return o.strip()

method partition*(self: ParticleList, index: int, num: int): void =
    self.p_count = num
    self.p_index = index
    self.p_size = self.N div self.p_count

method generate*(self: ParticleList, offset: int): int =
    self.particles = newSeq[PointParticle](self.p_size)
    for i in 0 .. self.p_size-1:
        let ind = self.p_index * self.p_size + i
        self.particles[i].copy(self.create(ind))
        self.particles[i].index = i + offset
    return offset + self.p_size

# -------------------------------------------------------------
type
    SingleParticle* = ref object of ParticleList
        particle*: PointParticle

proc initSingleParticle*(self: SingleParticle, particle: PointParticle): SingleParticle = 
    self.particle = particle
    self.particles = @[]
    self.N = 1
    return self

method count*(self: SingleParticle): int = return if self.p_index == 0: self.p_size else: 0
method `$`*(self: SingleParticle): string = return fmt"SingleParticle: {$self.particle}"

method generate*(self: SingleParticle, offset: int): int =
    if self.p_index == 0:
        self.particles = @[self.particle]
        self.particles[0].index = offset
        return offset + 1
    return offset

# -------------------------------------------------------------
type 
    UniformParticles* = ref object of ParticleList
        p0, p1, v0, v1: Vec

proc initUniformParticles*(self: UniformParticles, p0: Vec, p1: Vec, v0: Vec, v1: Vec, N: int): UniformParticles =
    self.p0 = p0
    self.p1 = p1
    self.v0 = v0
    self.v1 = v1
    self.N = N
    self.particles = @[]
    return self

method create*(self: UniformParticles, i: int): PointParticle =
    let f: float = i / (self.N - 1)
    let pos = lerp(self.p0, self.p1, f)
    let vel = lerp(self.v0, self.v1, f)
    var p = PointParticle()
    return p.initPointParticle(pos, vel, [0.0, 0.0])

# -------------------------------------------------------------
type 
    UniformParticles2D* = ref object of ParticleList
        p0, p1, v0, v1: Vec
        n2d: array[2, int]

proc initUniformParticles2D*(self: UniformParticles2D, p0: Vec, p1: Vec, v0: Vec, v1: Vec, N: array[2, int]): UniformParticles2D =
    self.p0 = p0
    self.p1 = p1
    self.v0 = v0
    self.v1 = v1
    self.n2d = N
    self.N = self.n2d[0] * self.n2d[1]
    self.particles = @[]
    return self

method create*(self: UniformParticles2D, i: int): PointParticle =
    let Nx = self.n2d[0]
    let Ny = self.n2d[1]

    var p = PointParticle()
    let fx = (i mod Nx).float / (Nx.float-1)
    let fy = (i div Nx).float / (Ny.float-1)
    let fv: Vec = [fx.float, fy.float]

    let pos = vlerp(self.p0, self.p1, fv)
    let vel = vlerp(self.v0, self.v1, fv)
    return p.initPointParticle(pos, vel, [0.0, 0.0])

# -------------------------------------------------------------
type 
    UniformRandomParticles* = ref object of UniformParticles

proc initUniformRandomParticles*(self: UniformRandomParticles, p0: Vec, p1: Vec, v0: Vec, v1: Vec, N: int): UniformRandomParticles =
    discard procCall self.UniformParticles.initUniformParticles(p0, p1, v0, v1, N)
    return self

method create*(self: UniformRandomParticles, i: int): PointParticle =
    var p = PointParticle()
    let f: float = rand(1.0)
    let pos = lerp(self.p0, self.p1, f)
    let vel = lerp(self.v0, self.v1, f)
    return p.initPointParticle(pos, vel, [0.0, 0.0])

# -------------------------------------------------------------
type 
    UniformRandomParticles2D* = ref object of UniformParticles2D

proc initUniformRandomParticles2D*(self: UniformRandomParticles2D, p0: Vec, p1: Vec, v0: Vec, v1: Vec, N: array[2, int]): UniformRandomParticles2D =
    discard procCall self.UniformParticles2D.initUniformParticles2D(p0, p1, v0, v1, N)
    return self

method create*(self: UniformRandomParticles2D, i: int): PointParticle =
    var p = PointParticle()
    let fx = rand(1.0)
    let fy = rand(1.0)
    let fv: Vec = [fx.float, fy.float]

    let pos = vlerp(self.p0, self.p1, fv)
    let vel = vlerp(self.v0, self.v1, fv)
    return p.initPointParticle(pos, vel, [0.0, 0.0])

# -------------------------------------------------------------
type 
    RadialUniformParticles* = ref object of ParticleList
        pos, a: Vec
        v: float

proc initRadialUniformParticles*(self: RadialUniformParticles, pos: Vec, v: float, a: array[2, float], N: int): RadialUniformParticles =
    self.pos = pos
    self.a = a
    self.v = v
    self.N = N
    self.particles = @[]
    return self

method create*(self: RadialUniformParticles, i: int): PointParticle =
    var f: float = i / (self.N - 1)
    var a = PI * (f * (self.a[1] - self.a[0]) + self.a[0])
    let vel = [self.v * math.sin(a), self.v * math.cos(a)]
    var p = PointParticle()
    return p.initPointParticle(self.pos, vel, [0.0, 0.0])
import ../plinko/vector

import std/strformat

type
    PointParticle* = object
        pos*, vel*, acc*: Vec
        time*: float
        index*: int
        active*: bool

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

type
    RefPointParticle* = ref object of RootObj
        pos*, vel*, acc*: Vec
        time*: float
        index*: int
        active*: bool

proc initRefPointParticle*(
        self: RefPointParticle,
        pos: Vec = [0.0, 0.0], 
        vel: Vec = [0.0, 0.0], 
        acc: Vec = [0.0, 0.0],
        index: int = 0): RefPointParticle =
    self.pos = pos
    self.vel = vel
    self.acc = acc
    self.time = 0
    self.active = true
    self.index = index
    return self

proc copy*(self: RefPointParticle, other: RefPointParticle): RefPointParticle {.discardable.} =
    self.pos = other.pos
    self.vel = other.vel
    self.acc = other.acc
    self.time = other.time
    self.index = other.index
    self.active = other.active
    return self

proc `$`*(self: RefPointParticle): string = fmt"RefParticle[{self.index}] <pos={$self.pos} vel={$self.vel}>"
const N = 1e8.int

var p: seq[PointParticle] = newSeq[PointParticle](N)
for i in 0 .. p.len-1:
    p[i].index = i

var last = 0
for i in 0 .. p.len-1:
    if p[i].index > last:
        last = p[i].index

echo last
echo getOccupiedMem() / N
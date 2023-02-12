import std/math
import std/strformat

import roots
import vector

var OBJECT_INDEX: int = 0

# -------------------------------------------------------------
type
    PointParticle* = ref object of RootObj
        pos*, vel*, acc*: Vec
        active*: bool
        index*: int

proc initPointParticle*(
        self: PointParticle,
        pos: Vec = [0.0, 0.0], 
        vel: Vec = [0.0, 0.0], 
        acc: Vec = [0.0, 0.0]): PointParticle =
    self.pos = pos
    self.vel = vel
    self.acc = acc
    self.index = OBJECT_INDEX
    OBJECT_INDEX = OBJECT_INDEX + 1
    return self

# -------------------------------------------------------------
type
    ParticleGroup* = ref object of RootObj

method index*(self: ParticleGroup, index: int): PointParticle {.base.} = result
method count*(self: ParticleGroup): int {.base.} = result

# -------------------------------------------------------------
type
    SingleParticle* = ref object of ParticleGroup
        particle: PointParticle

proc initSingleParticle*(self: SingleParticle, particle: PointParticle): SingleParticle = 
    self.particle = particle
    return self

method index*(self: SingleParticle, index: int): PointParticle = 
    if index == 1:
        return self.particle

method count*(self: SingleParticle): int = 1

# -------------------------------------------------------------
type
    ParticleList* = ref object of ParticleGroup
        particles: seq[PointParticle]

proc initParticleList*(self: ParticleList, particles: seq[PointParticle]): ParticleList = 
    self.particles = particles
    return self

method index*(self: ParticleList, index: int): PointParticle = result = self.particles[index]
method count*(self: ParticleList): int = len(self.particles)

proc partition*(self: ParticleList, total: int): seq[ParticleList] =
    let size = (self.count() div total)
    var list: seq[ParticleList] = @[]
    for i in 1 .. total:
        let particles: seq[PointParticle] = @[]
        for ind in 1 + (i-1)*size .. 1 + i*size:
            self.particles.add(self.particles[ind])
        list[i] = ParticleList().initParticleList(particles)
    return list

# -------------------------------------------------------------
type 
    UniformParticles* = ref object of ParticleList

proc initUniformParticles*(self: UniformParticles, p0: Vec, p1: Vec, v0: Vec, v1: Vec, N: int): UniformParticles =
    for i in 1 .. N:
        let f = i / N
        let pos = lerp(p0, p1, f)
        let vel = lerp(v0, v1, f)
        self.particles.add(PointParticle().initPointParticle(pos, vel, [0.0, 0.0]))
    return self

# -------------------------------------------------------------
type 
    UniformParticles2D* = ref object of ParticleList

proc initUniformParticles2D*(self: UniformParticles2D, p0: Vec, p1: Vec, v0: Vec, v1: Vec, N: array[2, int]): UniformParticles2D =
    let Nx = N[0]
    let Ny = N[1]
    let N = Nx * Ny

    for i in 1 .. N:
        let j = i - 1
        let fx = (j mod Nx) div Nx
        let fy = (j div Nx) div Ny
        let fv: Vec = [fx.float, fy.float]

        let pos = vlerp(p0, p1, fv)
        let vel = vlerp(v0, v1, fv)
        self.particles.add(PointParticle().initPointParticle(pos, vel, [0.0, 0.0]))
    return self

# -------------------------------------------------------------
type
    Object* = ref object of RootObj
        damp: float
        obj_index: int

proc initObject*(self: Object, damp: float): Object = 
    self.damp = damp
    self.obj_index = OBJECT_INDEX
    OBJECT_INDEX = OBJECT_INDEX + 1
    return self

#proc collide(self: Object, part0: Particle, parti: Particle, part1: Particle): tuple[Segment, Segment] =
    #[
      stotal is the total timestep of the particle from t0 to t1
      scoll is the segment from t0 to t_collision
      vel is the velocity at t0
    ]#
    #[
    let norm = self:normal(scoll)
    let dir = vector.reflect(vector.vsubv(stotal.p1, scoll.p1), norm)

    stotal.p0 = scoll.p1
    stotal.p1 = vector.vaddv(scoll.p1, dir)
    vseg.p0 = vector.reflect(vseg.p0, norm)
    vseg.p1 = vector.reflect(vseg.p1, norm)
    vseg.p0 = vector.vmuls(vseg.p0, self.damp)
    vseg.p1 = vector.vmuls(vseg.p1, self.damp)
    return stotal, vseg
    ]#

proc set_object_index*(self: Object, i: int) =
    self.obj_index = i

# ----------------------------------------------------------------
type 
    Segment* = ref object of Object
        p0*, p1*: Vec

proc initSegment*(self: Segment, p0: Vec = [0.0, 0.0], p1: Vec = [0.0, 0.0], damp: float = 1.0): Segment =
    self.p0 = p0
    self.p1 = p1 
    discard self.initObject(damp=damp)
    return self

proc `-`*(self: Segment): Segment = Segment().initSegment(self.p1, self.p0)
proc `$`*(self: Segment): string = fmt"{self.p0} -> {self.p1}"

proc intersection*(self: Segment, seg: Segment): (Segment, float) =
    # returns the length along seg1 when the intersection occurs (0, 1)
    let s0 = self.p0
    let e0 = self.p1
    let s1 = seg.p0 
    let e1 = seg.p1

    let d0 = e0 - s0
    let d1 = e1 - s1
    let fcross = d0.cross(d1)

    let t = (s1-s0).cross(d0) / fcross
    let p = -(s0-s1).cross(d1) / fcross

    if 0 <= t and t <= 1 and 0 <= p and p <= 1:
        return (self, t)
    return (nil, -1.0)

proc center*(self: Segment): Vec =
    return lerp(self.p0, self.p1, 0.5)

proc crosses*(self: Segment, seg: Segment): bool =
    return self.intersection(seg)[1] >= 0

proc normal*(self: Segment, seg: Segment): Vec =
    let c = self.center()
    let newp0 = c + rot90(self.p0 - c)
    let newp1 = c + rot90(self.p1 - c)
    let o = norm(newp1 - newp0)

    if (seg.p1 - seg.p0).dot(o) > 0:
        return -o
    else:
        return o

proc length*(self: Segment): float =
    return length(self.p1 - self.p0)

proc translate*(self: Segment, vec: Vec): Segment =
    return Segment(p0: self.p0 + vec, p1: self.p1 + vec, damp: self.damp)

proc rotate*(self: Segment, theta: float, center: Vec): Segment =
    let c = center
    return Segment(
        p0: c  + rotate(self.p0 - c, theta),
        p1: c  + rotate(self.p1 - c, theta),
        damp: self.damp
    )

proc rotate*(self: Segment, theta: float): Segment = self.rotate(theta, self.center())

proc scale*(self: Segment, s: float): Segment = 
    # assert(s > 0 and s < 1)
    return Segment(
        p0: lerp(self.p0, self.p1, 0.5 - s/2),
        p1: lerp(self.p0, self.p1, 0.5 + s/2),
        damp: self.damp
    )

# ---------------------------------------------------------------
type
    BezierCurve* = ref object of Object
        points: seq[Vec]
        coeff: seq[Vec]
        # const name: string = "bezier"

proc choose(self: BezierCurve, n: int, k: int): int =
    var val: int = 1
    for i in 1 .. k:
        val = val * (n + 1 - i) div i
    return val

proc get_coeff*(self: BezierCurve): seq[Vec] =
    #[
      cj = n! / (n-j)! sum_{i=0}^{j} (-1)^{i+j} P_i / (i!(j-i)!)
         = (n j) \sum_{i=0}^j (-1)^{i+j} (j i) P_i
    ]#
    let n = len(self.points)

    var coeff: seq[Vec] = newSeq[Vec](n-1)
    for j in 0 .. (n-1):
        coeff[j] = [0.0, 0.0]
        for i in 0 .. j:
            let odd = (if (i + j mod 2) == 0: 1 else: -1)
            let pre = odd * self.choose(j, i)
            coeff[j] = coeff[j+1] + pre.float * self.points[i+1]

        let pre = self.choose(n-1, j)
        coeff[j] = pre.float * coeff[j]

    return coeff

proc bezier_line_poly*(self: BezierCurve, s0: Vec, s1: Vec): seq[float] =
    let d = s1 - s0
    let m = [d[1], -d[0]]
    let b = m.dot(s0)

    var output: seq[float] = @[]
    for i in 0 .. len(self.coeff):
        output[i] = m.dot(self.coeff[i])
        if i == 0:
            output[i] = output[i] - b
    return output

proc f*(self: BezierCurve, t: float): Vec =
    let c = self.coeff
    var o: Vec = [0.0, 0.0]
    for i in countdown(len(c)-1, 1):
        o = t * o + c[i]
    return o

proc dfdt*(self: BezierCurve, t: float): Vec =
    let c = self.coeff
    var o: Vec = [0.0, 0.0]
    for i in countdown(len(c)-1, 2):
        o = t * o + (i-1).float * c[i]
    return o

proc btime_to_stime*(self: BezierCurve, seg: Segment, btime: float): float =
    let eval = self.f(btime)
    return ilerp(seg.p0, seg.p1, eval)

proc intersection_bt_st*(self: BezierCurve, seg: Segment): (float, float) =
    let btimes = roots.roots(self.bezier_line_poly(seg.p0, seg.p1))
    if len(btimes) == 0:
        return (0.0, 0.0)

    var times: seq[(float, float)] = @[]
    for i in 1 .. len(btimes):
        times.add((
            btimes[i],
            self.btime_to_stime(seg, btimes[i])
        ))

    var o: seq[float] = @[]
    for i in 1 .. len(times):
        let bt = times[i][0]
        let st = times[i][1]
        if st >= 0 and st <= 1 and bt >= 0 and bt <= 1:
            if len(o) == 0:
                o.add(bt)
                o.add(st)
            else:
                if o[1] < st:
                    o[0] = bt
                    o[1] = st

    if len(o) == 0:
        return (-1.0, -1.0)
    else:
        return (o[0], o[1])

proc intersection*(self: BezierCurve, seg: Segment): (BezierCurve, float) =
    let (_, st) = self.intersection_bt_st(seg)
    if st >= 0:
        return (self, st)
    return (nil, -1.0)

proc normal*(self: BezierCurve, seg: Segment): Vec =
    let (bt, _) = self.intersection_bt_st(seg)

    let tangent = norm(self.dfdt(bt))
    let o = rot90(tangent)
    let diff = seg.p1 - seg.p0
    if diff.dot(o) < 0:
        return -o
    return o

proc center*(self: BezierCurve): Vec =
    var c = [0.0, 0.0]
    for i, point in self.points:
        c = c + point
    return c / len(self.points).float

proc initBezierCurve*(self: BezierCurve, points: seq[array[2, float]], damp: float = 1.0): BezierCurve =
    self.points = points
    self.coeff = self.get_coeff()
    discard self.initObject(damp=damp)
    return self

# ---------------------------------------------------------------
type
    BezierCurveQuadratic* = ref object of BezierCurve

proc initBezierCurveQuadratic*(self: BezierCurveQuadratic, points: seq[Vec], damp: float = 1.0): BezierCurveQuadratic =
    discard self.initBezierCurve(points, damp)
    return self

proc get_coeff*(self: BezierCurveQuadratic): seq[Vec] =
    let p0 = self.points[0]
    let p1 = self.points[1]
    let p2 = self.points[2]

    var poly: seq[Vec] = @[]
    poly[2] = p0 - 2.0*p1 + p2
    poly[1] = 2.0*(p1 - p0)
    poly[0] = p0

    return poly

# ---------------------------------------------------------------
type
    BezierCurveCubic* = ref object of BezierCurve

proc initBezierCurveCubic*(self: BezierCurveCubic, points: seq[Vec], damp: float = 1.0): BezierCurveCubic =
    discard self.initBezierCurve(points, damp)
    return self

proc get_coeff*(self: BezierCurveCubic): seq[Vec] =
    let p0 = self.points[0]
    let p1 = self.points[1]
    let p2 = self.points[2]
    let p3 = self.points[3]

    var poly: seq[Vec] = @[]
    poly[3] = 3.0*(p1 - p2) + p3 - p0
    poly[2] = 3.0*(p0 + p2 - 2.0*p1)
    poly[1] = 3.0*(p1 - p0)
    poly[0] = p0

    return poly

# ---------------------------------------------------------------
type
    Circle* = ref object of Object
        pos*: Vec
        rad*: float
        radsq*: float

proc initCircle*(self: Circle, pos: Vec, rad: float, damp: float = 1.0): Circle =
    self.pos = pos
    self.rad = rad
    self.radsq = rad*rad
    discard self.initObject(damp=damp)
    return self

proc circle_line_poly*(self: Circle, seg: Segment): seq[float] =
    let dp = seg.p1 - seg.p0
    let dc = seg.p0 - self.pos

    let a = lengthsq(dp)
    let b = 2.0 * dp.dot(dc)
    let c = lengthsq(dc) - self.radsq
    return @[c, b, a]

proc intersection*(self: Circle, seg: Segment): (Circle, float) =
    let poly = self.circle_line_poly(seg)
    let root = roots.quadratic(poly)

    if len(root) == 0:
        return (nil, -1.0)

    if root[0] < 0 or root[0] > 1:
        if root[1] < 0 or root[1] > 1:
            return (nil, -1.0)
        return (self, root[1])
    return (self, root[0])

proc crosses*(self: Circle, seg: Segment): bool =
    let p0 = seg.p0
    let p1 = seg.p1
    let dr0 = lengthsq(p0 - self.pos)
    let dr1 = lengthsq(p1 - self.pos)
    return (dr0 < self.radsq and dr1 > self.radsq) or (dr0 > self.radsq and dr1 < self.radsq)

proc normal*(self:Circle, seg: Segment): Vec =
    let dr0 = seg.p0 - self.pos
    let dr1 = seg.p1 - self.pos
    let norm = norm(dr1)

    if lengthsq(dr0) <= lengthsq(dr1):
        return -norm
    return norm

proc center*(self: Circle): Vec = self.pos

proc translate*(self: Circle, vec: Vec): Circle =
    return Circle(pos: self.pos + vec, rad: self.rad, damp: self.damp)

proc scale*(self: Circle, s: float): Circle = 
    return Circle(pos: self.pos, rad: self.rad * s, damp: self.damp)

proc rotate*(self: Circle, theta: float): Circle =
    return Circle(pos: self.pos, rad: self.rad, damp: self.damp)


# ----------------------------------------------------------------
type 
    MaskFunction* = proc(theta: float): bool

type
    MaskedCircle* = ref object of Circle
        mask: MaskFunction

proc initMaskedCircle*(self: MaskedCircle, pos: Vec, rad: float, damp: float = 1.0, mask: MaskFunction): MaskedCircle =
    self.mask = mask
    discard self.initCircle(pos=pos, rad=rad, damp=damp)
    return self

proc intersection*(self: MaskedCircle, seg: Segment): (MaskedCircle, float) =
    let time = self.intersection(seg)[1]
    if time < 0:
        return (nil, -1.0)

    let x = lerp(seg.p0, seg.p1, time)
    let c = self.pos
    let theta = math.arctan2(c[1] - x[1], c[0] - x[0]) + PI

    if self.mask(theta):
        return (self, time)
    return (nil, -1.0)

proc circle_nholes*(nholes: int, eps: float, offset: float): MaskFunction =
    return proc(theta: float): bool =
        let r: float = nholes.float * (theta - offset) / (2.0 * PI)
        return abs(r - floor(r + 0.5)) > eps

proc circle_angle_range*(amin: float, amax: float): MaskFunction =
    return proc(theta: float): bool =
        return (theta > amin) and (theta < amax)

# ---------------------------------------------------------------
type
    Box* = ref object of Object
        ll*, lu*, uu*, ul*: Vec
        segments: seq[Segment]

proc initBox*(self: Box, ll: Vec, uu: Vec, damp: float = 1.0): Box =
    self.damp = damp
    let lu = [ll[0], uu[1]]
    let ul = [uu[0], ll[1]]

    self.ll = ll
    self.lu = lu
    self.uu = uu
    self.ul = ul

    self.segments = @[
        Segment().initSegment(self.ll, self.lu),
        Segment().initSegment(self.lu, self.uu),
        Segment().initSegment(self.uu, self.ul),
        Segment().initSegment(self.ul, self.ll)
    ]
    discard self.initObject(damp=damp)
    return self

proc center*(self: Box): Vec =
    return (self.ll + self.uu)/2.0

proc intersection*(self: Box, seg: Segment): (Segment, float) =
    var min_time = 1e100
    var min_obj: Segment

    for line in self.segments:
        let (_, t) = line.intersection(seg)
        if t >= 0 and (t < min_time or min_time > 1e10):
            min_time = t
            min_obj = line

    if min_time >= 0 and min_time < 1e10:
        return (min_obj, min_time)
    return (nil, -1.0)

proc normal*(self: Box, seg: Segment): Vec =
    let (line, _) = self.intersection(seg)
    return line.normal(seg)

proc crosses*(self: Box, seg: Segment): bool =
    let (bx0, bx1) = (self.ll[0], self.uu[0])
    let (by0, by1) = (self.ll[1], self.uu[1])
    let (p0, p1) = (seg.p0, seg.p1)

    let inx0 = (p0[0] > bx0 and p0[0] < bx1)
    let inx1 = (p1[0] > bx0 and p1[0] < bx1)
    let iny0 = (p0[1] > by0 and p0[1] < by1)
    let iny1 = (p1[1] > by0 and p1[1] < by1)

    return (inx0 and iny0) xor (inx1 and iny1)

proc contains*(self: Box, pt: Vec): bool =
    let (bx0, bx1) = (self.ll[0], self.uu[0])
    let (by0, by1) = (self.ll[1], self.uu[1])

    let inx = (pt[0] > bx0 and pt[0] < bx1)
    let iny = (pt[1] > by0 and pt[1] < by1)
    return inx and iny

# ---------------------------------------------------------------
type
    Polygon* = ref object of Object
        N: int
        points: seq[Vec]
        segments: seq[Segment]
        com: Vec

proc wrap*(self: Polygon, pts: seq[Vec]): seq[Vec] =
    var o: seq[Vec] = @[]
    for i, pt in pts:
        o.add(pt)
    o.add(pts[0])
    return o

proc get_segments*(self: Polygon, pts: seq[Vec], damp: float): seq[Segment] =
    var segs: seq[Segment] = @[]
    for i, pt in pts[0 .. pts.len-2]:
        let seg = Segment().initSegment(p0=pts[i], p1=pts[i+1], damp=damp)
        segs.add(seg)
    return segs

proc center*(self: Polygon): Vec =
    var (a, com) = (0.0, [0.0, 0.0])
    for i, pt in self.points[0 .. self.points.len - 2]:
        let (p0, p1) = (self.points[i], self.points[i+1])
        let c = p0.cross(p1)
        a = a + c / 2
        com = com + (p0 + p1) * (c/6)
    return com / a

proc initPolygon*(self: Polygon, points: seq[Vec], damp: float = 1.0): Polygon =
    self.N = len(points)
    self.points = self.wrap(points)
    self.segments = self.get_segments(self.points, damp)
    self.com = self.center()
    discard self.initObject(damp=damp)
    return self

proc intersection*(self: Polygon, seg: Segment): (Segment, float) =
    var min_time = 1e100
    var min_obj: Segment

    for line in self.segments:
        let (_, t) = line.intersection(seg)
        if t >= 0 and (t < min_time or min_time > 1e10):
            min_time = t
            min_obj = line

    if min_time >= 0 and min_time < 1e10:
        return (min_obj, min_time)
    return (nil, -1.0)

proc normal*(self: Polygon, seg: Segment): Vec =
    let (line, _) = self.intersection(seg)
    return line.normal(seg)

proc crosses*(self: Polygon, seg: Segment): bool =
    return self.intersection(seg)[1] >= 0

proc contains*(self: Polygon, pt: Vec): bool =
    #- FIXME this is wrong
    return false

proc translate*(self: Polygon, vec: Vec): Polygon =
    var points: seq[Vec] = @[]
    for pt in self.points:
        points.add(pt + vec)
    return Polygon().initPolygon(points, self.damp)

proc rotate*(self: Polygon, theta: float): Polygon =
    let c = self.center()

    var points: seq[Vec] = @[]
    for pt in self.points:
        points.add(rotate(pt-c, theta)+c)
    return Polygon().initPolygon(points, self.damp)

proc scale*(self: Polygon, s: float): Polygon = 
    let c: Vec = self.center()
    let f: float = 1.0 - s/2.0

    var points: seq[Vec] = @[]
    for i, pt in self.points:
        points.add(vector.lerp(self.points[i], c, f))
    return Polygon().initPolygon(points, self.damp)

proc coordinate_bounding_box*(self: Polygon): Box =
    var (x0, y0) = (1e100, 1e100)
    var (x1, y1) = (-1e100, -1e100)

    for i, pt in  self.points:
        let pt = self.points[i]
        x0 = min(pt[0], x0)
        y0 = min(pt[1], y0)
        x1 = max(pt[0], x1)
        y1 = max(pt[1], y1)

    return Box().initBox([x0, y0], [x1, y1])

# -------------------------------------------------------------
type 
    Rectangle* = ref object of Polygon

proc initRectangle*(self: Rectangle, ll: Vec, uu: Vec, damp: float = 1.0): Rectangle =
    let box: Box = Box().initBox(ll, uu)
    let points: seq[Vec] = @[box.uu, box.ul, box.ll, box.lu]
    discard self.initPolygon(points, damp)
    return self

# -------------------------------------------------------------
type 
    RegularPolygon* = ref object of Polygon

proc initRegularPolygon*(self: RegularPolygon, N: int, pos: Vec, size: float, damp: float = 1.0): RegularPolygon =
    var points: seq[Vec] = @[]
    for i in 0 .. N-1:
        let t: float = i.float * 2.0 * PI / N.float
        let v: Vec = [cos(t), sin(t)]
        points.add(pos + size * v)
    discard self.initPolygon(points, damp)
    return self
{.warning[LockLevel]:off.}
import std/math
import std/strformat

import particles
import roots
import vector

# -------------------------------------------------------------
type
    Object* = ref object of RootObj
        damp*: float
        index*: int
        name*: string
        buffer_sign*: float

type 
    Segment* = ref object of Object
        p0*, p1*: Vec

type
    Box* = ref object of Object
        ll*, lu*, uu*, ul*: Vec
        bottom*: Segment
        top*: Segment
        segments*: seq[Segment]

proc initObject*(self: Object, damp: float, name: string = ""): Object = 
    self.damp = damp
    self.buffer_sign = if damp < 0: -1.0 else: 1.0
    self.index = 0
    if name.len > 0:
        self.name = name
    return self

proc initSegment*(self: Segment, p0: Vec = [0.0, 0.0], p1: Vec = [0.0, 0.0], damp: float = 1.0, name: string = ""): Segment =
    self.p0 = p0
    self.p1 = p1 
    discard self.initObject(damp=damp, name=name)
    return self

proc initBox*(self: Box, ll: Vec, uu: Vec, damp: float = 1.0, name: string = ""): Box =
    let lu = [ll[0], uu[1]]
    let ul = [uu[0], ll[1]]

    self.ll = ll
    self.lu = lu
    self.uu = uu
    self.ul = ul

    self.segments = @[
        Segment().initSegment(self.ll, self.lu, damp=damp),
        Segment().initSegment(self.lu, self.uu, damp=damp),
        Segment().initSegment(self.uu, self.ul, damp=damp),
        Segment().initSegment(self.ul, self.ll, damp=damp)
    ]
    self.top = self.segments[1]
    self.bottom = self.segments[3]
    discard self.initObject(damp=damp, name=name)
    return self

method `$`*(self: Object): string {.base.} = "Object"
method t*(self: Object, t: float): Vec {.base.} = [0.0, 0.0]
method crosses*(self: Object, seg: Segment): bool {.base.} = false
method normal*(self: Object, seg: Segment): Vec {.base.} = [0.0, 0.0]
method center*(self: Object): Vec {.base.} = [0.0, 0.0]
method translate*(self: Object, v: Vec): Object {.base.} = Object()
method scale*(self: Object, s: float): Object {.base.} = Object()
method rotate*(self: Object, a: float): Object {.base.} = Object()
method intersection*(self: Object, seg: Segment): (Object, float) {.base.} = (nil, -1.0)
method boundary*(self: Object): Box {.base.} = Box()
method by_name*(self: Object, name: string): Object {.base.} =
    if self.name == name:
        return self

proc set_index*(self: Object, i: int) = 
    self.index = i
    if self.name.len == 0:
        self.name = "object-" & $self.index

# ----------------------------------------------------------------
proc `-`*(self: Segment): Segment = Segment().initSegment(self.p1, self.p0)
method `$`*(self: Segment): string = fmt"Segment: '{self.name}' {self.p0} -> {self.p1}"

method intersection*(self: Segment, seg: Segment): (Object, float) =
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

method center*(self: Segment): Vec =
    return lerp(self.p0, self.p1, 0.5)

method crosses*(self: Segment, seg: Segment): bool =
    return self.intersection(seg)[1] >= 0

method normal*(self: Segment, seg: Segment): Vec =
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

method translate*(self: Segment, vec: Vec): Object =
    return Segment().initSegment(p0=self.p0 + vec, p1=self.p1 + vec, damp=self.damp)

proc rotate*(self: Segment, theta: float, center: Vec): Segment =
    let c = center
    return Segment(
        p0: c  + rotate(self.p0 - c, theta),
        p1: c  + rotate(self.p1 - c, theta),
        damp: self.damp
    )

proc rotate*(self: Segment, theta: float): Segment = self.rotate(theta, self.center())

method scale*(self: Segment, s: float): Object = 
    return Segment(
        p0: lerp(self.p0, self.p1, 0.5 - s/2),
        p1: lerp(self.p0, self.p1, 0.5 + s/2),
        damp: self.damp
    )

method boundary*(self: Segment): Box =
    return Box().initBox(ll=min(self.p0, self.p1), uu=max(self.p0, self.p1))

method t*(self: Segment, t: float): Vec =
    return lerp(self.p0, self.p1, t)

# ---------------------------------------------------------------
#[
type
    BezierCurve* = ref object of Object
        points: seq[Vec]
        coeff: seq[Vec]

method `$`*(self: BezierCurve): string = fmt"BezierCurve: '{self.name}' {self.points.len}"

proc choose(self: BezierCurve, n: int, k: int): int =
    var val: int = 1
    for i in 1 .. k:
        val = val * (n + 1 - i) div i
    return val

method get_coeff*(self: BezierCurve): seq[Vec] {.base.} =
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

method line_poly*(self: BezierCurve, s0: Vec, s1: Vec): array[IX, float] {.base.} =
    return [0.0, 0.0]

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
    let btimes = roots(self.bezier_line_poly(seg.p0, seg.p1))
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

method intersection*(self: BezierCurve, seg: Segment): (Object, float) =
    let (_, st) = self.intersection_bt_st(seg)
    if st >= 0:
        return (self, st)
    return (nil, -1.0)

method normal*(self: BezierCurve, seg: Segment): Vec =
    let (bt, _) = self.intersection_bt_st(seg)

    let tangent = norm(self.dfdt(bt))
    let o = rot90(tangent)
    let diff = seg.p1 - seg.p0
    if diff.dot(o) < 0:
        return -o
    return o

method center*(self: BezierCurve): Vec =
    var c = [0.0, 0.0]
    for i, point in self.points:
        c = c + point
    return c / len(self.points).float

proc initBezierCurve*(self: BezierCurve, points: seq[Vec], damp: float = 1.0, name: string = ""): BezierCurve =
    self.points = points
    self.coeff = self.get_coeff()
    discard self.initObject(damp=damp, name=name)
    return self

# ---------------------------------------------------------------
type
    BezierCurveQuadratic* = ref object of BezierCurve

proc initBezierCurveQuadratic*(self: BezierCurveQuadratic, points: seq[Vec], damp: float = 1.0): BezierCurveQuadratic =
    discard self.initBezierCurve(points, damp)
    return self

method `$`*(self: BezierCurveQuadratic): string = fmt"BezierCurveQuadratic {self.points.len}"

method get_coeff*(self: BezierCurveQuadratic): seq[Vec] =
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

method `$`*(self: BezierCurveCubic): string = fmt"BezierCurveCubic {self.points.len}"

method get_coeff*(self: BezierCurveCubic): seq[Vec] =
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
]#

# ---------------------------------------------------------------
type
    Circle* = ref object of Object
        pos*: Vec
        rad*: float
        radsq*: float

proc initCircle*(self: Circle, pos: Vec, rad: float, damp: float = 1.0, name: string = ""): Circle =
    self.pos = pos
    self.rad = rad
    self.radsq = rad*rad
    discard self.initObject(damp=damp, name=name)
    return self

method `$`*(self: Circle): string = fmt"Circle[{self.index}]: '{self.name}' {self.pos}, rad={self.rad},{self.radsq}, damp={self.damp}"

proc circle_line_poly*(self: Circle, seg: Segment): array[3, float] =
    let dp = seg.p1 - seg.p0
    let dc = seg.p0 - self.pos

    var poly: array[3, float]
    poly[2] = dp[0]*dp[0] + dp[1]*dp[1]
    poly[1] = 2.0 * (dp[0]*dc[0] + dp[1]*dc[1])
    poly[0] = dc[0]*dc[0] + dc[1]*dc[1] - self.radsq
    # poly[2] = lengthsq(dp)
    # poly[1] = 2.0 * dp.dot(dc)
    # poly[0] = lengthsq(dc) - self.radsq
    return poly

method crosses*(self: Circle, seg: Segment): bool =
    let p0 = seg.p0
    let p1 = seg.p1
    let dr0 = lengthsq(p0 - self.pos)
    let dr1 = lengthsq(p1 - self.pos)
    return (dr0 < self.radsq and dr1 > self.radsq) or (dr0 > self.radsq and dr1 < self.radsq)

method intersection*(self: Circle, seg: Segment): (Object, float) =
    let poly = self.circle_line_poly(seg)
    let root = roots.quadratic(poly)

    if root[0] < 0 or root[0] > 1:
        if root[1] < 0 or root[1] > 1:
            return (nil, -1.0)
        return (self, root[1])
    return (self, root[0])

method normal*(self:Circle, seg: Segment): Vec =
    let dr0 = seg.p0 - self.pos
    let dr1 = seg.p1 - self.pos
    let norm = norm(dr1)

    if lengthsq(dr0) <= lengthsq(dr1):
        return -norm
    return norm

method center*(self: Circle): Vec = self.pos

method translate*(self: Circle, vec: Vec): Object =
    return Circle().initCircle(pos=self.pos + vec, rad=self.rad, damp=self.damp)

method scale*(self: Circle, s: float): Object = 
    return Circle().initCircle(pos=self.pos, rad=self.rad * s, damp=self.damp)

proc rotate*(self: Circle, theta: float): Circle =
    return Circle().initCircle(pos=self.pos, rad=self.rad, damp=self.damp)

method boundary*(self: Circle): Box =
    return Box().initBox(ll=self.pos-[self.rad, self.rad], uu=self.pos+[self.rad, self.rad])

method t*(self: Circle, t: float): Vec =
    return self.pos + self.rad * [math.sin(2*PI*t), math.cos(2*PI*t)]

# ----------------------------------------------------------------
type 
    MaskFunction* = proc(theta: float): bool

type
    MaskedCircle* = ref object of Circle
        mask: MaskFunction
        rotation: float

proc initMaskedCircle*(self: MaskedCircle, pos: Vec, rad: float, mask: MaskFunction, 
        rotation: float = 0.0, damp: float = 1.0, name: string = ""): MaskedCircle =
    self.mask = mask
    self.rotation = rotation
    discard self.initCircle(pos=pos, rad=rad, damp=damp)
    return self

method intersection*(self: MaskedCircle, seg: Segment): (Object, float) =
    let (_, time) = procCall intersection(self.Circle, seg)
    if time < 0:
        return (nil, -1.0)

    let x = lerp(seg.p0, seg.p1, time)
    let c = self.pos
    let theta = math.arctan2(c[1] - x[1], c[0] - x[0]) + PI

    if self.mask(theta - self.rotation):
        return (self, time)
    return (nil, -1.0)

method translate*(self: MaskedCircle, vec: Vec): Object =
    return MaskedCircle().initMaskedCircle(pos=self.pos + vec, rad=self.rad, damp=self.damp, 
        mask=self.mask, rotation=self.rotation)

method scale*(self: MaskedCircle, s: float): Object = 
    return MaskedCircle().initMaskedCircle(pos=self.pos, rad=self.rad * s, damp=self.damp, 
        mask=self.mask, rotation=self.rotation)

method rotate*(self: MaskedCircle, s: float): Object =
    return MaskedCircle().initMaskedCircle(pos=self.pos, rad=self.rad, rotation=self.rotation+s, 
        damp=self.damp, mask=self.mask)

method `$`*(self: MaskedCircle): string = 
    fmt"MaskedCircle[{self.index}]: '{self.name}' {self.pos} rad={self.rad} damp={self.damp} rot={self.rotation}"

proc circle_nholes*(nholes: int, eps: float, offset: float): MaskFunction =
    let angle = offset * PI
    return proc(theta: float): bool =
        let r: float = nholes.float * (theta - angle) / (2.0 * PI)
        return abs(r - floor(r + 0.5)) > eps

proc circle_angle_range*(amin: float, amax: float): MaskFunction =
    return proc(theta: float): bool =
        return (theta > amin) and (theta < amax)

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

method center*(self: Polygon): Vec =
    var (a, com) = (0.0, [0.0, 0.0])
    for i, pt in self.points[0 .. self.points.len - 2]:
        let (p0, p1) = (self.points[i], self.points[i+1])
        let c = p0.cross(p1)
        a = a + c / 2
        com = com + (p0 + p1) * (c/6)
    return com / a

proc initPolygon*(self: Polygon, points: seq[Vec], damp: float = 1.0, name: string = ""): Polygon =
    self.N = len(points)
    self.points = self.wrap(points)
    self.segments = self.get_segments(self.points, damp)
    self.com = self.center()
    discard self.initObject(damp=damp, name=name)
    return self

method intersection*(self: Polygon, seg: Segment): (Object, float) =
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

method normal*(self: Polygon, seg: Segment): Vec =
    let (line, _) = self.intersection(seg)
    return line.normal(seg)

method crosses*(self: Polygon, seg: Segment): bool =
    return self.intersection(seg)[1] >= 0

proc contains*(self: Polygon, pt: Vec): bool =
    #- FIXME this is wrong
    return false

method translate*(self: Polygon, vec: Vec): Object =
    var points: seq[Vec] = @[]
    for pt in self.points:
        points.add(pt + vec)
    return Polygon().initPolygon(points, self.damp)

method rotate*(self: Polygon, theta: float): Object =
    let c = self.center()

    var points: seq[Vec] = @[]
    for pt in self.points:
        points.add(rotate(pt-c, theta)+c)
    return Polygon().initPolygon(points, self.damp)

method scale*(self: Polygon, s: float): Object = 
    let c: Vec = self.center()
    let f: float = 1.0 - s/2.0

    var points: seq[Vec] = @[]
    for i, pt in self.points:
        points.add(vector.lerp(self.points[i], c, f))
    return Polygon().initPolygon(points, self.damp)

method t*(self: Polygon, v: float): Vec =
    let n = self.segments.len
    var sf = n.float * v
    if sf.int >= n:
        sf = n.float - 1.0
    return self.segments[sf.int].t(sf - sf.int.float)

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

method `$`*(self: Polygon): string =
    var o = &"Polygon N={self.points.len-1}:\n"
    for seg in self.segments:
        o &= &"  {$seg}\n"
    return o

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

# ---------------------------------------------------------------
method `$`*(self: Box): string = fmt"Box[{self.index}]: '{self.name}' {$self.ll} -> {$self.uu}, damp={self.damp}"

method center*(self: Box): Vec =
    return (self.ll + self.uu)/2.0

method intersection*(self: Box, seg: Segment): (Object, float) =
    var min_time = 1e100
    var min_obj: Segment

    for line in self.segments:
        let (_, t) = line.intersection(seg)
        if t >= 0 and t <= 1 and (t < min_time or min_time > 1e10):
            min_time = t
            min_obj = line

    if min_time >= 0 and min_time < 1:
        return (min_obj, min_time)
    return (nil, -1.0)

method normal*(self: Box, seg: Segment): Vec =
    let (line, _) = self.intersection(seg)
    return line.normal(seg)

method crosses*(self: Box, seg: Segment): bool =
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

method translate*(self: Box, x: Vec): Object =
    return Box().initBox(ll=self.ll+x, uu=self.uu+x, damp=self.damp)

method scale*(self: Box, s: float): Object =
    let c = self.center()
    let ll = (self.ll - c) * s + c
    let uu = (self.uu - c) * s + c
    return Box().initBox(ll=ll, uu=uu, damp=self.damp)

method rotate*(self: Box, a: float): Object =
    let pts = @[self.ll, self.lu, self.uu, self.ul]
    return Polygon().initPolygon(pts, damp=self.damp).rotate(a)

method by_name*(self: Box, name: string): Object =
    if self.name == name:
        return self
    for seg in self.segments:
        if seg.name == name:
            return seg

method t*(self: Box, v: float): Vec =
    if v >= 0.00 and v < 0.25:
        return self.segments[0].t((v - 0.00) / 0.25)
    if v >= 0.25 and v < 0.50:
        return self.segments[1].t((v - 0.25) / 0.25)
    if v >= 0.50 and v < 0.75:
        return self.segments[2].t((v - 0.50) / 0.25)
    if v >= 0.75 and v <= 1.00:
        return self.segments[3].t((v - 0.75) / 0.25)

# -------------------------------------------------------------
method collide*(self: Object, part0: PointParticle, parti: PointParticle, part1: PointParticle): (Segment, Segment) {.base.} =
    let scoll = Segment(p0: part0.pos, p1: parti.pos)
    let stotal = Segment(p0: parti.pos, p1: part1.pos)
    let vseg = Segment(p0:parti.vel, p1:part1.vel)

    if self.damp < 0:
        vseg.p0 = vseg.p0 * abs(self.damp)
        vseg.p1 = vseg.p1 * abs(self.damp)
        return (stotal, vseg)

    let norm = self.normal(scoll)
    let dir = reflect(part1.pos - parti.pos, norm)
    stotal.p1 = parti.pos + dir
    vseg.p0 = reflect(vseg.p0, norm) * self.damp
    vseg.p1 = reflect(vseg.p1, norm) * self.damp
    return (stotal, vseg)
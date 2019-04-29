local util = require('plinko.util')
local vector = require('plinko.vector')
local roots = require('plinko.roots')

function xor(a, b)
    return (a and not b) or (b and not a)
end

-- ---------------------------------------------------------------
Object = util.class()
function Object:init(cargs)
    self.cargs = cargs or {}
    self.damp = self.cargs.damp or 1.0
end

function Object:collide(stotal, scoll, vel)
    --[[
    --  stotal is the total timestep of the particle from t0 to t1
    --  scoll is the segment from t0 to t_collision
    --  vel is the velocity at t0
    --]]
    local norm = self:normal(scoll)
    local dir = vector.reflect(vector.vsubv(stotal.p1, scoll.p1), norm)

    stotal.p0 = scoll.p1
    stotal.p1 = vector.vaddv(scoll.p1, dir)
    vel = vector.reflect(vel, norm)
    vel = vector.vmuls(vel, self.damp)
    return stotal, vel
end

-- ---------------------------------------------------------------
BezierCurve = util.class(Object)
function BezierCurve:init(points, cargs)
    Object.init(self, cargs)
    self.points = points
    self.coeff = self:_coeff()
    self.name = 'bezier'
end

function BezierCurve:_choose(n, k)
    local out = 1
    for i = 1, k do
        out = out * (n + 1 - i) / i
    end
    return out
end

function BezierCurve:_coeff()
    --[[
    --  cj = n! / (n-j)! sum_{i=0}^{j} (-1)^{i+j} P_i / (i!(j-i)!)
    --     = (n j) \sum_{i=0}^j (-1)^{i+j} (j i) P_i
    --]]
    local n = #self.points

    local coeff = {}
    for j = 0, n-1 do
        coeff[j+1] = {0, 0}
        for i = 0, j do
            local odd = (math.fmod(i + j, 2) == 0) and 1 or -1
            local pre = odd * self:_choose(j, i)
            coeff[j+1][1] = coeff[j+1][1] + pre*self.points[i+1][1]
            coeff[j+1][2] = coeff[j+1][2] + pre*self.points[i+1][2]
        end

        local pre = self:_choose(n-1, j)
        coeff[j+1][1] = pre * coeff[j+1][1]
        coeff[j+1][2] = pre * coeff[j+1][2]
    end

    return coeff
end

function BezierCurve:_bezier_line_poly(s0, s1)
    local dx = s1[1] - s0[1]
    local dy = s1[2] - s0[2]
    local m = {dy, -dx}
    local b = vector.vdotv(m, s0)

    local out = {}
    for i = 1, #self.coeff do
        out[i] = vector.vdotv(m, self.coeff[i])
        if i == 1 then
            out[i] = out[i] - b
        end
    end
    return out
end

function BezierCurve:f(t)
    local c = self.coeff
    local out = {0, 0}
    for i = #c, 1, -1 do
        out[1] = t*out[1] + c[i][1]
        out[2] = t*out[2] + c[i][2]
    end
    return out
end

function BezierCurve:dfdt(t)
    local c = self.coeff
    local out = {0, 0}
    for i = #c, 2, -1 do
        out[1] = t*out[1] + (i-1)*c[i][1]
        out[2] = t*out[2] + (i-1)*c[i][2]
    end
    return out
end

function BezierCurve:_intersection_bt_st(seg)
    local btimes = roots.roots(self:_bezier_line_poly(seg.p0, seg.p1))
    if not btimes then return nil end

    local times = {}
    for i = 1, #btimes do
        times[#times + 1] = {
            btimes[i],
            self:_btime_to_stime(seg, btimes[i])
        }
    end

    local out = nil
    for i = 1, #times do
        local bt, st = times[i][1], times[i][2]
        if st >= 0 and st <= 1 and bt >= 0 and bt <= 1 then
            if not out then
                out = {bt, st}
            else
                if out[2] < st then
                    out = {bt, st}
                end
            end
        end
    end

    if not out then
        return nil, nil
    else
        return out[1], out[2]
    end
end

function BezierCurve:_btime_to_stime(seg, btime)
    local eval = self:f(btime)
    return vector.ilerp(seg.p0, seg.p1, eval)
end

function BezierCurve:intersection(seg)
    local bt, st = self:_intersection_bt_st(seg)
    if st then
        return self, st
    end
    return nil, nil
end

function BezierCurve:normal(seg)
    local bt, st = self:_intersection_bt_st(seg)

    local tangent = vector.vnorm(self:dfdt(bt))
    local out = vector.rot90(tangent)
    local diff = vector.vsubv(seg.p1, seg.p0)
    if vector.vdotv(diff, out) < 0 then
        return vector.vneg(out)
    end
    return out
end

function BezierCurve:center()
    local c = {0, 0}
    for i = 1, #self.points do
        c = vector.vaddv(c, self.points[i])
    end
    return vector.vdivs(c, #self.points)
end

-- ---------------------------------------------------------------
BezierCurveQuadratic = util.class(BezierCurve)
function BezierCurveQuadratic:init(points, cargs)
    BezierCurve.init(self, points, cargs)
end

function BezierCurveQuadratic:_coeff()
    local p1 = self.points[1]
    local p2 = self.points[2]
    local p3 = self.points[3]

    local xpoly = {0, 0, 0}
    local ypoly = {0, 0, 0}
    xpoly[3] = p1[1] - 2*p2[1] + p3[1]
    ypoly[3] = p1[2] - 2*p2[2] + p3[2]
    xpoly[2] = 2*(p2[1] - p1[1])
    ypoly[2] = 2*(p2[2] - p1[2])
    xpoly[1] = p1[1]
    ypoly[1] = p1[2]

    return {
        {xpoly[1], ypoly[1]},
        {xpoly[2], ypoly[2]},
        {xpoly[3], ypoly[3]},
    }
end

-- ---------------------------------------------------------------
BezierCurveCubic = util.class(BezierCurve)
function BezierCurveCubic:init(points, cargs)
    BezierCurve.init(self, points, cargs)
end

function BezierCurveCubic:_coeff()
    local p1 = self.points[1]
    local p2 = self.points[2]
    local p3 = self.points[3]
    local p4 = self.points[4]

    local xpoly = {0, 0, 0, 0}
    local ypoly = {0, 0, 0, 0}
    xpoly[4] = 3*(p2[1] - p3[1]) + p4[1] - p1[1]
    ypoly[4] = 3*(p2[2] - p3[2]) + p4[2] - p1[2]
    xpoly[3] = 3*(p1[1] + p3[1] - 2*p2[1])
    ypoly[3] = 3*(p1[2] + p3[2] - 2*p2[2])
    xpoly[2] = 3*(p2[1] - p1[1])
    ypoly[2] = 3*(p2[2] - p1[2])
    xpoly[1] = p1[1]
    ypoly[1] = p1[2]

    return {
        {xpoly[1], ypoly[1]},
        {xpoly[2], ypoly[2]},
        {xpoly[3], ypoly[3]},
        {xpoly[4], ypoly[4]}
    }
end

-- ---------------------------------------------------------------
Circle = util.class(Object)
function Circle:init(pos, rad, cargs)
    Object.init(self, cargs)
	self.pos = pos
	self.rad = rad
    self.radsq = rad*rad
    self.name = 'circle'
end

function Circle:circle_line_poly(p0, p1)
    local dp = vector.vsubv(p1, p0)
    local dc = vector.vsubv(p0, self.pos)

    local a = vector.vlensq(dp)
    local b = 2 * vector.vdotv(dp, dc)
    local c = vector.vlensq(dc) - self.radsq
    return {c, b, a}
end

function Circle:intersection(seg)
    local p0, p1 = seg.p0, seg.p1
    local diff = vector.vsubv(p1, p0)
    local poly = self:circle_line_poly(p0, p1)
    local root = roots.quadratic(poly)

    if not root then
        return nil, nil
    end

    if root[1] < 0 or root[1] > 1 then
        if root[2] < 0 or root[2] > 1 then
            return nil, nil
        end
        return self, root[2]
    end
    return self, root[1]
end

function Circle:crosses(seg)
    local p0, p1 = seg.p0, seg.p1
    local dr0 = vector.vlensq(vector.vsubv(p0, self.pos))
    local dr1 = vector.vlensq(vector.vsubv(p1, self.pos))
    return (dr0 < self.radsq and dr1 > self.radsq) or (dr0 > self.radsq and dr1 < self.radsq)
end

function Circle:normal(seg)
    local dr0 = vector.vsubv(seg.p0, self.pos)
    local dr1 = vector.vsubv(seg.p1, self.pos)
    local norm = vector.vnorm(dr1)

    if vector.vlensq(dr0) <= vector.vlensq(dr1) then
        return vector.vneg(norm)
    end
    return norm
end

function Circle:center()
    return self.pos
end

function Circle:translate(vec)
    return Circle(vector.vaddv(self.pos, vec), self.rad, self.cargs)
end

function Circle:scale(s)
    return Circle(self.pos, self.rad * s, self.cargs)
end

function Circle:rotate(theta)
    return Circle(self.pos, self.rad, self.cargs)
end

-- ----------------------------------------------------------------
MaskedCircle = util.class(Circle)
function MaskedCircle:init(pos, rad, func, cargs)
    Circle.init(self, pos, rad, cargs)
    self.func = func
    self.name = 'maskedcircle'
end

function MaskedCircle:intersection(seg)
    local obj, time = Circle.intersection(self, seg)
    if not obj then
        return nil, nil
    end

    local x = seg.p0[1] + (seg.p1[1] - seg.p0[1]) * time
    local y = seg.p0[2] + (seg.p1[2] - seg.p0[2]) * time
    local c = self.pos
    local theta = math.atan2(c[2] - y, c[1] - x) + math.pi

    if self.func(theta) then
        return obj, time
    end
    return nil, nil
end

function circle_nholes(nholes, eps, offset)
    return function(theta)
        local r = nholes * theta / (2 * math.pi)
        return math.abs(r - math.floor(r + 0.5)) > eps
    end
end

function circle_angle_range(amin, amax)
    return function(theta)
        return (theta > amin) and (theta < amax)
    end
end

function circle_single_angle(angle, eps)
end

-- ----------------------------------------------------------------
Segment = util.class(Object)
function Segment:init(p0, p1, cargs)
    Object.init(self, cargs)
    self.p0 = p0
    self.p1 = p1
    self.name = 'segment'
end

function Segment:intersection(seg)
    -- returns the length along seg1 when the intersection occurs (0, 1)
    local s0, e0 = self.p0, self.p1
    local s1, e1 = seg.p0, seg.p1

    local d0 = vector.vsubv(e0, s0)
    local d1 = vector.vsubv(e1, s1)
    local cross = vector.vcrossv(d0, d1)

    --if cross < 1e-27 then
    --    return nil, nil
    --end

    local t = vector.vcrossv(vector.vsubv(s1, s0), d0) / cross
    local p = -vector.vcrossv(vector.vsubv(s0, s1), d1) / cross

    if 0 <= t and t <= 1 and 0 <= p and p <= 1 then
        return self, t
    end
    return nil, nil
end

function Segment:center()
    return vector.lerp(self.p0, self.p1, 0.5)
end

function Segment:crosses(seg)
    local o, t = self:intersection(seg)
    return not o == nil
end

function Segment:normal(seg)
    local point = seg.p1
    local c = self:center()
    local newp0 = vector.vaddv(c, vector.rot90(vector.vsubv(self.p0, c)))
    local newp1 = vector.vaddv(c, vector.rot90(vector.vsubv(self.p1, c)))
    local out = vector.vnorm(vector.vsubv(newp1, newp0))

    local diff = vector.vsubv(seg.p1, seg.p0)
    if vector.vdotv(diff, out) > 0 then
        return out
    else
        return vector.vneg(out)
    end
end

function Segment:length()
    return vector.vlen(vector.vsubv(self.p1, self.p0))
end

function Segment:translate(vec)
    return Segment(vector.vaddv(self.p0, vec), vector.vaddv(self.p1, vec), self.cargs)
end

function Segment:rotate(theta, center)
    local c = center or self:center()
    return Segment(
        vector.vaddv(c, vector.rotate(vector.vsubv(self.p0, c), theta)),
        vector.vaddv(c, vector.rotate(vector.vsubv(self.p1, c), theta)), self.cargs
    )
end

function Segment:scale(s)
    assert(s > 0 and s < 1)
    return Segment(
        vector.lerp(self.p0, self.p1, 0.5 - s/2),
        vector.lerp(self.p0, self.p1, 0.5 + s/2), self.cargs
    )
end

function Segment:update(p0, p1)
    vector.copy(p0, self.p0)
    vector.copy(p1, self.p1)
end

-- ---------------------------------------------------------------
Box = util.class(Object)
function Box:init(ll, uu, cargs)
    Object.init(self, cargs)

    lu = {ll[1], uu[2]}
    ul = {uu[1], ll[2]}

    self.ll = ll
    self.lu = lu
    self.uu = uu
    self.ul = ul

    self.segments = {
        Segment(self.ll, self.lu),
        Segment(self.lu, self.uu),
        Segment(self.uu, self.ul),
        Segment(self.ul, self.ll)
    }
    self.name = 'box'
end

function Box:center()
    return {(self.ll[1] + self.uu[1])/2, (self.ll[2] + self.uu[2])/2}
end

function Box:intersection(seg)
    local min_time = 1e100
    local min_seg = nil

    for i = 1, 4 do
        local line = self.segments[i]
        local o, t = line:intersection(seg)
        if t and t < min_time and t >= 0 then
            min_time = t
            min_seg = o
        end
    end

    if min_seg then
        return min_seg, min_time
    end
    return nil, nil
end

function Box:crosses(seg)
    local bx0, bx1 = self.ll[1], self.uu[1]
    local by0, by1 = self.ll[2], self.uu[2]
    local p0, p1 = seg.p0, seg.p1

    local inx0 = (p0[1] > bx0 and p0[1] < bx1)
    local inx1 = (p1[1] > bx0 and p1[1] < bx1)
    local iny0 = (p0[2] > by0 and p0[2] < by1)
    local iny1 = (p1[2] > by0 and p1[2] < by1)

    return xor(xinx0 and iny0, inx1 and iny1)
    --return xor(inx0, inx1) and xor(iny0, iny1)
end

function Box:contains(pt)
    local bx0, bx1 = self.ll[1], self.uu[1]
    local by0, by1 = self.ll[2], self.uu[2]

    local inx = (pt[1] > bx0 and pt[1] < bx1)
    local iny = (pt[2] > by0 and pt[2] < by1)
    return inx and iny
end

function Box:update(ll, uu)
    vector.copy(ll, self.ll)
    vector.copy(uu, self.uu)
    vector.copy({ll[1], uu[2]}, self.lu)
    vector.copy({uu[1], ll[2]}, self.ul)

    self.segments[1]:update(self.ll, self.lu)
    self.segments[2]:update(self.lu, self.uu)
    self.segments[3]:update(self.uu, self.ul)
    self.segments[4]:update(self.ul, self.ll)
end

-- ---------------------------------------------------------------
Polygon = util.class(Object)
function Polygon:init(points, cargs)
    self.N = #points
    self.points = self:_wrap(points)
    self.segments = self:_segments(self.points, cargs)
    self.com = self:center()

    Object.init(self, cargs)
    self.name = 'polygon'
end

function Polygon:_wrap(pts)
    local out = {}
    for i = 1, #pts do
        out[#out + 1] = {pts[i][1], pts[i][2]}
    end
    out[#out + 1] = {pts[1][1], pts[1][2]}
    return out
end

function Polygon:_segments(pts, cargs)
    local seg = {}
    for i = 1, #pts-1 do
        seg[#seg + 1] = Segment(pts[i], pts[i+1], cargs)
    end
    return seg
end

function Polygon:center()
    local a, com = 0, {0, 0}
    for i = 1, #self.points-1 do
        local p0, p1 = self.points[i], self.points[i+1]
        local cross = vector.vcrossv(p0, p1)
        a = a + cross / 2
        com = vector.vaddv(com, vector.vmuls(vector.vaddv(p0, p1), cross/6))
    end
    return vector.vdivs(com, a)
end

function Polygon:intersection(seg)
    local min_time = 1e100
    local min_seg = nil

    for i = 1, self.N do
        local line = self.segments[i]
        local o, t = line:intersection(seg)
        if t and t < min_time and t >= 0 then
            min_time = t
            min_seg = o
        end
    end

    if min_seg then
        return min_seg, min_time
    end
    return nil, nil
end

function Polygon:crosses(seg)
    local obj, time = self:intersection(seg)
    return obj and true or false
end

function Polygon:contains(pt)
    -- FIXME this is wrong
    return nil
end

function Polygon:translate(vec)
    local points = {}
    for i = 1, #self.points-1 do
        points[i] = vector.vaddv(self.points[i], vec)
    end
    return Polygon(points, self.cargs)
end

function Polygon:rotate(theta)
    local c = self.com

    local points = {}
    for i = 1, #self.points-1 do
        points[i] = vector.vaddv(vector.rotate(vector.vsubv(self.points[i], c), theta), c)
    end
    return Polygon(points, self.cargs)
end

function Polygon:scale(s)
    local c = self.com
    local f = 1 - s/2

    local points = {}
    for i = 1, #self.points-1 do
        points[i] = vector.lerp(self.points[i], c, f)
    end
    return Polygon(points, self.cargs)
end

function Polygon:coordinate_bounding_box()
    local x0, y0 = 1e100, 1e100
    local x1, y1 = -1e100, -1e100

    for i = 1, #self.points-1 do
        local pt = self.points[i]
        x0 = math.min(pt[1], x0)
        y0 = math.min(pt[2], y0)
        x1 = math.max(pt[1], x1)
        y1 = math.max(pt[2], y1)
    end

    return {{x0, y0}, {x1, y1}}
end

-- -------------------------------------------------------------
Rectangle = util.class(Polygon)
function Rectangle:init(ll, uu, cargs)
    local points = {
        {ll[1], ll[2]},
        {ll[1], uu[2]},
        {uu[1], uu[2]},
        {uu[1], ll[2]}
    }
    Polygon.init(self, points, cargs)
end

-- -------------------------------------------------------------
RegularPolygon = util.class(Polygon)
function RegularPolygon:init(N, pos, size, cargs)
    local points = {}

    for i = 0, N-1 do
        local t = i * 2 * math.pi / N
        points[#points + 1] = vector.vaddv(pos, {size*math.cos(t), size*math.sin(t)})
    end
    Polygon.init(self, points, cargs)
end

-- -------------------------------------------------------------
PointParticle = util.class(Object)
function PointParticle:init(pos, vel, acc, index)
    self.pos = pos or {0, 0}
    self.vel = vel or {0, 0}
    self.acc = acc or {0, 0}
    self.active = true

    if index == nil then
        if PointParticle.index == nil then
            PointParticle.index = 1
        else
            PointParticle.index = PointParticle.index + 1
        end
        self.index = PointParticle.index
    else
        self.index = index
    end
end

-- -------------------------------------------------------------
ParticleGroup = util.class()
function ParticleGroup:init() end
function ParticleGroup:index(i) return nil end
function ParticleGroup:count() return 0 end

-- -------------------------------------------------------------
SingleParticle = util.class(ParticleGroup)
function SingleParticle:init(pos, vel, acc, index)
    self.particle = PointParticle(pos, vel, acc, index)
end
function SingleParticle:index(i) return i == 1 and self.particle or nil end
function SingleParticle:count() return 1 end

-- -------------------------------------------------------------
UniformParticles = util.class(ParticleGroup)
function UniformParticles:init(p0, p1, v0, v1, N)
    self.p0 = p0
    self.p1 = p1
    self.v0 = v0
    self.v1 = v1
    self.N = N
    self.particles = {}
    for i = 1, N do
        local f = i / self.N
        local pos = vector.lerp(self.p0, self.p1, f)
        local vel = vector.lerp(self.v0, self.v1, f)
        local p = PointParticle(pos, vel, {0, 0}, i)
        self.particles[i] = p
    end
end

function UniformParticles:index(i)
    return self.particles[i]
end

function UniformParticles:count()
    return self.N
end

function UniformParticles:partition(total)
    local out = {}
    for i = 1, total do
        local p0 = vector.lerp(self.p0, self.p1, (i-1) / total)
        local p1 = vector.lerp(self.p0, self.p1, (i+0) / total)
        local v0 = vector.lerp(self.v0, self.v1, (i-1) / total)
        local v1 = vector.lerp(self.v0, self.v1, (i+0) / total)

        out[i] = UniformParticles(p0, p1, v0, v1, math.floor(self.N / total))
    end
    return out
end

return {
    circle_masks = {
        circle_nholes = circle_nholes,
        circle_angle_range = circle_angle_range
    },
    Box = Box,
    Circle = Circle,
    MaskedCircle = MaskedCircle,
    Segment = Segment,
    Polygon = Polygon,
    Rectangle = Rectangle,
    RegularPolygon = RegularPolygon,
    BezierCurve = BezierCurve,
    BezierCurveCubic = BezierCurveCubic,
    BezierCurveQuadratic = BezierCurveQuadratic,

    PointParticle = PointParticle,
    SingleParticle = SingleParticle,
    UniformParticles = UniformParticles
}

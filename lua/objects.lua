local math = require('math')
local util = require('util')
local vector = require('vector')

function xor(a, b)
    return (a and not b) or (b and not a)
end 

function sign(x)
    return x > 0 and 1 or -1
end

local function root_quadratic(poly)
    local a, b, c = poly[3], poly[2], poly[1]

    if a == 0 then
        if b == 0 then
            return nil
        end
        return {-c / b, nan}
    end

    local desc = b*b - 4*a*c
    if desc < 0 then
        return nil
    end

    local x1 = (-b - sign(b) * math.sqrt(desc)) / (2*a)
    local x2 = c / (a * x1)
    return x1 < x2 and {x1, x2} or {x2, x1}
end

-- ---------------------------------------------------------------
Object = util.class()
function Object:init()
end

-- ---------------------------------------------------------------
Circle = util.class(Object)
function Circle:init(pos, rad)
    Object.init(self)
	self.pos = pos
	self.rad = rad
    self.radsq = rad*rad
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
    local root = root_quadratic(poly)

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

-- ----------------------------------------------------------------
MaskedCircle = util.class(Circle)
function MaskedCircle:init(pos, rad, func)
    Circle.init(self, pos, rad)
    self.func = func
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

function circle_single_angle(angle, eps)
end

-- ----------------------------------------------------------------
Segment = util.class(Object)
function Segment:init(p0, p1)
    self.p0 = p0
    self.p1 = p1
end

function Segment:intersection(seg)
    -- returns the length along seg1 when the intersection occurs (0, 1)
    local s0, e0 = self.p0, self.p1
    local s1, e1 = seg.p0, seg.p1

    local d0 = vector.vsubv(e0, s0)
    local d1 = vector.vsubv(e1, s1)
    local cross = vector.vcrossv(d0, d1)

    --if cross < 1e-15 then
    --    return self, 0
    --end

    local t = vector.vcrossv(vector.vsubv(s1, s0), d0) / cross
    local p = -vector.vcrossv(vector.vsubv(s0, s1), d1) / cross

    if 0 <= t and t <= 1 and 0 <= p and p <= 1 then
        return self, t
    end
    return nil, nil
end

function Segment:crosses(seg)
    local o, t = self:intersection(seg)
    return not o == nil
end

function Segment:normal(seg)
    local point = seg.p1
    local center = vector.vmuls(vector.vaddv(self.p0, self.p1), 0.5)
    local newp0 = vector.vaddv(center, vector.rot90(vector.vsubv(self.p0, center)))
    local newp1 = vector.vaddv(center, vector.rot90(vector.vsubv(self.p1, center)))
    local out = vector.vnorm(vector.vsubv(newp1, newp0))

    local diff = vector.vsubv(seg.p1, seg.p0)
    if vector.vdotv(diff, out) > 0 then
        return out
    else
        return vector.vneg(out)
    end
end

-- ---------------------------------------------------------------
Box = util.class(Object)
function Box:init(ll, uu)
    self.ll = {ll[1], ll[2]}
    self.lu = {ll[1], uu[2]}
    self.uu = {uu[1], uu[2]}
    self.ul = {uu[1], ll[2]}

    self.segments = {
        Segment(self.ll, self.lu),
        Segment(self.lu, self.uu),
        Segment(self.uu, self.ul),
        Segment(self.ul, self.ll)
    }
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

    return xor(inx0, inx1) and xor(iny0, iny1)
end

function Box:contains(pt)
    local bx0, bx1 = self.ll[1], self.uu[1]
    local by0, by1 = self.ll[2], self.uu[2]

    local inx = (pt[1] > bx0 and pt[1] < bx1)
    local iny = (pt[2] > by0 and pt[2] < by1)
    return inx and iny
end 

-- -------------------------------------------------------------
PointParticle = util.class(Object)
function PointParticle:init(pos, vel, acc)
    self.pos = pos or {0, 0}
    self.vel = vel or {0, 0}
    self.acc = acc or {0, 0}
end


local objects = {
    Circle=Circle,
    MaskedCircle=MaskedCircle,
    circle_nholes=circle_nholes,
    Segment=Segment,
    Box=Box,
    PointParticle=PointParticle
}
return objects

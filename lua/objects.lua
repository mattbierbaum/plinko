local util = require('util')
local vector = require('vector')

function xor(a, b)
    return (a and not b) or (b and not a)
end 

function sign(x)
    return x > 0 and 1 or -1
end

function root_quadratic(poly)
    local a, b, c = poly[3], poly[2], poly[1]
    local desc = b^2 - 4*a*c

    if (desc < 0) then
        return nil
    end

    local x1 = (-b - sign(b) * math.sqrt(desc)) / (2*a)
    local x2 = c / (a * x1)
    return x1 < x2 and {x1, x2} or {x2, x1}
end

-- ---------------------------------------------------------------
Circle = util.class()
function Circle:init(pos, rad)
	self.pos = pos
	self.rad = rad
    self.radsq = rad*rad
end

function Circle:circle_line_poly(p0, p1)
    local dp = vector.vsubv(p1, p0)
    local dc = vector.vsubv(p0, self.pos)

    local a = vector.vlensq(dp)
    local b = 2 * vector.vdotv(dp, dc)
    local c = vector.vlensq(dc) - self.rad^2
    return {c, b, a}
end

function Circle:intersection(seg)
    local p0, p1 = seg.p0, seg.p1
    local diff = vector.vsubv(p1, p0)
    local poly = self:circle_line_poly(p0, p1)
    local root = root_quadratic(poly)

    if not root then
        return nil
    end

    if root[1] < 0 or root[1] > 1 then
        if root[2] < 0 or root[2] > 1 then
            return nil
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

    if vector.vlensq(dr0) <= self.radsq then
        return vector.vneg(norm)
    end
    return norm
end

-- ----------------------------------------------------------------
Segment = util.class()
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

    if math.abs(cross) < 1e-15 then
        return nil, nil
    end
        
    local t = vector.vcrossv(vector.vsubv(s1, s0), d0) / cross 
    
    if 0 <= t and t <= 1 then
        return self, t
    end
    return nil, nil
end

function Segment:crosses(seg)
    return not self:intersection(seg) == nil
end

function Segment:normal(seg)
    local point = seg.p1
    local center = vector.vmuls(vector.vaddv(self.p0, self.p1), 0.5)
    local newp0 = vector.vaddv(center, vector.rot90(vector.vsubv(self.p0, center)))
    local newp1 = vector.vaddv(center, vector.rot90(vector.vsubv(self.p1, center)))
    local out = vector.vsubv(newp1, newp0)
    return vector.vnorm(out)
end

-- ---------------------------------------------------------------
Box = util.class()
function Box:init(ll, ur)
    self.segments = {
        Segment({ll[1], ll[2]}, {ll[1], ur[2]}),
        Segment({ll[1], ur[2]}, {ur[1], ur[2]}),
        Segment({ur[1], ur[2]}, {ur[1], ll[2]}),
        Segment({ur[1], ll[2]}, {ll[1], ll[2]})
    }
    self.c0 = ll
    self.c1 = ur
end

function Box:intersection(seg)
    for _, line in pairs(self.segments) do
        local o, t = line:intersection(seg)
        if t then
            return o, t
        end
    end
    return nil, nil
end

function Box:crosses(seg)
    local bx0, bx1 = self.c0[1], self.c1[1]
    local by0, by1 = self.c0[2], self.c1[2]
    local p0, p1 = seg.p0, seg.p1

    local inx0 = (p0[1] > bx0 and p0[1] < bx1)
    local inx1 = (p1[1] > bx0 and p1[1] < bx1)
    local iny0 = (p0[2] > by0 and p0[2] < by1)
    local iny1 = (p1[2] > by0 and p1[2] < by1)

    return xor(inx0, inx1) and xor(iny0, iny1)
end

-- -------------------------------------------------------------
PointParticle = util.class()
function PointParticle:init(pos, vel, acc)
    self.pos = pos
    self.vel = vel
    self.acc = acc
end

function PointParticle:__tostring()
    return string.format("<(%f, %f); (%f, %f)>", self.pos.x, self.pos.y, self.vel.x, self.vel.y)
end

local objects = {
    Circle=Circle,
    Segment=Segment,
    Box=Box,
    PointParticle=PointParticle
}
return objects

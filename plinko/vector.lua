local vector = {}

local sqrt = math.sqrt
local sin = math.sin
local cos = math.cos

function vector.copy(v0, v1) v1[1] = v0[1]; v1[2] = v0[2] end
function vector.vadds(v0, s) return {v0[1] + s, v0[2] + s} end
function vector.vsubs(v0, s) return {v0[1] - s, v0[2] - s} end
function vector.vmuls(v0, s) return {v0[1] * s, v0[2] * s} end
function vector.vdivs(v0, s) return {v0[1] / s, v0[2] / s} end

function vector.vaddv(v0, v1) return {v0[1] + v1[1], v0[2] + v1[2]} end
function vector.vsubv(v0, v1) return {v0[1] - v1[1], v0[2] - v1[2]} end
function vector.vdivv(v0, v1) return {v0[1] / v1[1], v0[2] / v1[2]} end
function vector.vdotv(v0, v1) return v0[1]*v1[1] + v0[2]*v1[2] end
function vector.rot90(v)      return {-v[2], v[1]} end  -- {-y, x}
function vector.vneg(v)       return {-v[1], -v[2]} end
function vector.vlensq(v)     return v[1]*v[1] + v[2]*v[2] end
function vector.vlen(v)       return sqrt(v[1]*v[1] + v[2]*v[2]) end
function vector.vcrossv(v0, v1) return v0[1] * v1[2] - v0[2] * v1[1] end

function vector.vnorm(v)
    local len = 1.0 / vector.vlen(v)
    return {v[1]*len, v[2]*len}
end

function vector.reflect(v, n)
    -- v - 2*(v dot n) n
    local ddot = vector.vdotv(v, n)
    return vector.vsubv(v, vector.vmuls(n, 2*ddot))
end

function vector.lerp(p0, p1, t)
    -- p0 + (p1 - p0) * t, written more numerically stable though
    return {
        (1 - t)*p0[1] + t*p1[1],
        (1 - t)*p0[2] + t*p1[2]
    }
end

function vector.ilerp(p0, p1, p)
    if math.abs(p1[1] - p0[1]) < math.abs(p1[2] - p0[2]) then
        return (p[2] - p0[2]) / (p1[2] - p0[2])
    else
        return (p[1] - p0[1]) / (p1[1] - p0[1])
    end
end

function vector.rotate(v, theta)
    local c = cos(theta)
    local s = sin(theta)
    return {v[1]*c - v[2]*s, v[1]*s + v[2]*c}
end

return vector

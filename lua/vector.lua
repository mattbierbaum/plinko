local vector = {}

function vector.vadds(v0, s) return {v0[1] + s, v0[2] + s} end
function vector.vsubs(v0, s) return {v0[1] - s, v0[2] - s} end
function vector.vmuls(v0, s) return {v0[1] * s, v0[2] * s} end

function vector.vaddv(v0, v1) return {v0[1] + v1[1], v0[2] + v1[2]} end
function vector.vsubv(v0, v1) return {v0[1] - v1[1], v0[2] - v1[2]} end
function vector.vdotv(v0, v1) return v0[1]*v1[1] + v0[2]*v1[2] end

function vector.vcrossv(v0, v1)
    return v0[1] * v1[2] - v0[2] * v1[1]
end

function vector.vlen(v)
    return math.sqrt(vector.vdotv(v, v))
end

function vector.vlensq(v)
    return vector.vdotv(v, v)
end

function vector.vnorm(v)
    local len = 1.0 / vector.vlen(v)
    return {v[1]*len, v[2]*len}
end

function vector.vneg(v)
    return {-v[1], -v[2]}
end

function vector.reflect(v, n)
    -- v - 2*(v dot n) n
    local ddot = vector.vdotv(v, n)
    return vector.vsubv(v, vector.vmuls(n, 2*ddot))
end

function vector.rot90(v)
    -- {-y, x}
    return {-v[2], v[1]}
end

function vector.lerp(p0, p1, t)
    -- p0 + (p1 - p0) * t
    return {
        (1 - t)*p0[1] + t*p1[1],
        (1 - t)*p0[2] + t*p1[2]
    }
end

return vector

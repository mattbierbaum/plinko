local os = require('os')
local json = require('dkjson')

local function elapsed(f)
    local t0 = os.clock()
    local val1, val2 = f()
    local t1 = os.clock()
    return (t1 - t0), val1, val2
end

local function timeit(f)
    local t, k, s = 1/0, 0, os.clock()
    while true do
        k = k + 1
        local tx, val1, val2 = elapsed(f)
        t = math.min(t, tx)
        if k > 5 and (os.clock() - s) >= 2 then break end
    end
    print(t)
end

--[[
-- https://github.com/ers35/luastatic
--]]
function tprint(t)
    print(json.encode(t, {indent=true}))
end

function sign(x)
    return x > 0 and 1 or -1
end

function vadds(v0, s) return {x=v0.x + s; y=v0.y + s} end
function vsubs(v0, s) return {x=v0.x - s; y=v0.y - s} end
function vmuls(v0, s) return {x=v0.x * s; y=v0.y * s} end

function vaddv(v0, v1) return {x=v0.x + v1.x; y=v0.y + v1.y} end
function vsubv(v0, v1) return {x=v0.x - v1.x; y=v0.y - v1.y} end
function vdotv(v0, v1) return v0.x * v1.x + v0.y * v1.y end

function vcrossv(v0, v1)
    return v0.x * v1.y - v0.y * v1.x
end

function vlen(v)
    return math.sqrt(vdotv(v, v))
end

function vlensq(v)
    return vdotv(v, v)
end

function vnorm(v)
    local len = 1.0 / vlen(v)
    return {x=v.x*len, y=v.y*len}
end

-- ===============================================================
-- ===============================================================
function force_gravity(...)
    return {x=0; y=-1}
end

function force_none(...)
    return {x=0; y=0}
end

function integrate_euler(particle, dt)
    local pos, vel, acc = particle.pos, particle.vel, particle.acc
    local outp = vaddv(vel, vmuls(acc, dt))
    local outv = vaddv(pos, vmuls(outv, dt))

    return {pos=outp; vel=outv; acc=acc}
end

-- ===============================================================
-- ===============================================================
function intersect_circle_seg(circle, seg)
    local p0, p1 = seg.p0, seg.p1
    local diff = vsubv(p1, p0)
    local poly = circle_line_poly(circle, p0, p1)
    local root = root_quadratic(poly)

    if not root then
        return nil
    end

    if root[1] < 0 or root[1] > 1 then
        if root[2] < 0 or root[1] > 1 then
            return nil
        end
        return vaddv(p0, vmuls(diff, root[2]))
    end
    return vaddv(p0, vmuls(diff, root[1]))
end

function intersect_seg_seg(seg0, seg1)
    local s0, e0 = seg0.p0, seg0.p1
    local s1, e1 = seg1.p0, seg1.p1

    local d0 = vsubv(e0, s0)
    local d1 = vsubv(e1, s1)
    local cross = vcrossv(d0, d1)

    if math.abs(cross) < 1e-15 then
        return nil
    end
        
    local t = vcrossv(vsubv(s1, s0), d0) / cross 
    
    if 0 <= t and t <= 1 then
        return vaddv(s1, vmuls(d1, t))
    else
        return nil
    end
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

function circle_line_poly(circle, p0, p1)
    local dp = vsubv(p1, p0)
    local dc = vsubv(p0, circle.pos)

    local a = vlensq(dp)
    local b = 2 * vdotv(dp, dc)
    local c = vlensq(dc) - circle.rad^2
    return {c, b, a}
end

-- ===============================================================
-- ===============================================================
function simulate(particle)
end


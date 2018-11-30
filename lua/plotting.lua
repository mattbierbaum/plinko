--[[
--  For blend modes, there are color channels and alpha channels, which can be treated
--  differently. In the color channels, a is the active layer (above) and b is the
--  background layer (below).
--
--  http://www.pegtop.net/delphi/articles/blendmodes/softlight.htm
--  https://en.wikipedia.org/wiki/Blend_modes
--  https://en.wikipedia.org/wiki/Alpha_compositing
--]]
local function clip(x)
    return math.max(0, math.min(x, 1))
end

local function gw3c(a)
    if a < 0.25 then
        return ((16*a - 12)*a + 4)*a
    else
        return math.sqrt(a)
    end
end

local blendmodes = {}

function blendmodes.normal(a, b)        return a end
function blendmodes.additive(a, b)      return a + b end
function blendmodes.subtractive(a, b)   return a + b - 1 end
function blendmodes.stamp(a, b)         return b + 2*a - 1 end
function blendmodes.average(a, b)       return (a + b) / 2 end
function blendmodes.multiply(a, b)      return a * b end
function blendmodes.screen(a, b)        return 1 - (1-a)*(1-b) end
function blendmodes.darken(a, b)        return b < a and b or a end
function blendmodes.lighten(a, b)       return b > a and b or a end
function blendmodes.difference(a, b)    return math.abs(a - b) end
function blendmodes.negation(a, b)      return 1 - math.abs(1 - a - b) end
function blendmodes.exclusion(a, b)     return a + b - 2*a*b
function blendmodes.overlay(a, b)       return b < 0.5 and 2*a*b or 1 - 2*(1-a)*(1-b) end
function blendmodes.hardlight(a, b)     return a < 0.5 and 2*a*b or 1 - 2*(1-a)*(1-b) end
function blendmodes.interpolative(a, b) return 0.5 - 0.25*math.cos(math.pi*a) - 0.25*math.cos(math.pi*b) end
function blendmodes.dodge(a, b)         return a / (1 - b) end
function blendmodes.pegtop(a, b)        return (1 - 2*a)*b*b + 2*a*b end
function blendmodes.illusions(a, b)     return math.pow(b, math.pow(2, 2*(0.5 - a))) end

function blendmodes.softlight(a, b)
    if a < 0.5 then
        return 2*a*b - b*b*(1 - 2*a)
    else
        return 2*b*(1-a) + math.sqrt(b)*(2*a - 1)
    end
end

function blendmodes.softdodge(a, b)
    if a + b < 1 then
        return 0.5 * b / (1 - a)
    else
        return 1 - 0.5*(1 - a) / b
    end
end

function blendmodes.w3c(a, b)
    if a < 0.5 then
        return b - (1 - 2*a)*b*(1 - b)
    else
        return b + (2*a - 1)*(gw3c(b) - b)
    end
end

function blendmodes.apply(func, ca, cb)
    out = {0, 0, 0}
    for i = 1, 3 do
        out[i] = clip(func(ca[i], cb[i]))
    end
    return out
end

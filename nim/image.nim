#[
  For bl modes, there are color channels and alpha channels, which can be treated
  differently. In the color channels, a is the active layer (above) and b is the
  background layer (below).

  http://www.pegtop.net/delphi/articles/blmodes/softlight.htm
  https://en.wikipedia.org/wiki/Bl_modes
  https://en.wikipedia.org/wiki/Alpha_compositing
]#
import std/math

proc clip*(x: float): float = return max(0.0, min(x, 1.0))

proc gw3c*(a: float): float = 
    if a < 0.25:
        return ((16*a - 12)*a + 4)*a
    else:
        return sqrt(a)

proc blendmode_normal*(a: float, b: float): float =        return a 
proc blendmode_max*(a: float, b: float): float =           return max(a, b)
proc blendmode_additive*(a: float, b: float): float =      return a + b 
proc blendmode_subtractive*(a: float, b: float): float =   return a + b - 1.0
proc blendmode_stamp*(a: float, b: float): float =         return b + 2.0*a - 1.0
proc blendmode_average*(a: float, b: float): float =       return (a + b) / 2.0
proc blendmode_multiply*(a: float, b: float): float =      return a * b 
proc blendmode_screen*(a: float, b: float): float =        return 1 - (1-a)*(1-b) 
proc blendmode_darken*(a: float, b: float): float =        return if b < a: b else: a 
proc blendmode_lighten*(a: float, b: float): float =       return if b > a: b else: a 
proc blendmode_difference*(a: float, b: float): float =    return abs(a - b) 
proc blendmode_negation*(a: float, b: float): float =      return 1.0 - abs(1.0 - a - b) 
proc blendmode_exclusion*(a: float, b: float): float =     return a + b - 2.0*a*b 
proc blendmode_overlay*(a: float, b: float): float =       return if b < 0.5: 2.0*a*b else: 1.0 - 2.0*(1-a)*(1-b) 
proc blendmode_hardlight*(a: float, b: float): float =     return if a < 0.5: 2.0*a*b else: 1.0 - 2.0*(1-a)*(1-b) 
proc blendmode_interpolative*(a: float, b: float): float = return 0.5 - 0.25*cos(PI*a) - 0.25*cos(PI*b) 
proc blendmode_dodge*(a: float, b: float): float =         return a / (1.0 - b) 
proc blendmode_pegtop*(a: float, b: float): float =        return (1 - 2*a)*b*b + 2*a*b 
proc blendmode_illusions*(a: float, b: float): float =     return pow(b, pow(2, 2*(0.5 - a))) 

proc blendmode_softlight*(a: float, b: float): float =
    if a < 0.5:
        return 2*a*b - b*b*(1 - 2*a)
    else:
        return 2*b*(1-a) + math.sqrt(b)*(2*a - 1)

proc blendmode_softdodge*(a: float, b: float): float =
    if a + b < 1:
        return 0.5 * b / (1 - a)
    else:
        return 1 - 0.5*(1 - a) / b
    
proc blendmodes_w3c*(a: float, b: float): float =
    if a < 0.5:
        return b - (1 - 2*a)*b*(1 - b)
    else:
        return b + (2*a - 1)*(gw3c(b) - b)

#[
proc blendmode_apply*(func, ca: float, cb: float)
    out = {0, 0, 0}
    for i = 1, 3 do
        out[i] = clip(func(ca[i], cb[i]))
    
    return out

proc hist*(arr: seq[float], nbins: int, docut: bool): seq[float] =
    local docut = docut ~= nil and docut or true

    local min, max = array:minmax_nozero()
    local bins = alloc.create_array(nbins, 'int')
    local norm = 1.0 / (max - min)

    for i = 0, array.size-1 do
        local v = array.arr[i]
        if docut and v > min then
            local n = math.floor(math.max(math.min(nbins*(v - min)*norm, nbins-1), 0))
            bins.arr[n] = bins.arr[n] + 1
        
    

    return bins

local function cdf(data)
    local out = alloc.create_array(data.shape, 'float')
    local total = 0.0
    local tsum = data:sum()

    for i = 0, data.size-1 do
        local v = data.arr[i]
        total = total + v
        out.arr[i] = total / tsum
    

    return out

function norms.eq_hist(data: float, nbins)
    local nbins = nbins ~= nil and nbins or 256*256
    local min, max = data:minmax_nozero()

    local df = cdf(hist(data: float, nbins))
    local dx = (max - min) / nbins

    function bincenter(i)
        return min + dx/2 + i*dx
    

    local b0 = bincenter(0)
    local b1 = bincenter(nbins)

    local out = alloc.create_array(data.shape, 'float')
    for i = 0, data.size-1 do
        local v = data.arr[i]
        if v <= b0 then out.arr[i] = 0.0 
        if v >= b1 then out.arr[i] = 1.0 
        if v > b0 and v < b1 then
            local bin = math.floor((v - b0)/dx)
            local x1 = bincenter(bin)
            local x2 = bincenter(bin+1)
            local y1 = df.arr[bin]
            local y2 = df.arr[bin+1]
            out.arr[i] = y1 + (y2 - y1)/(x2 - x1) * (v - x1)

    return out

function norms.clip(data: float, vmin, vmax)
    local out = alloc.create_array(data.shape, 'float')
    local min, max = data:minmax()

    min = vmin ~= nil and vmin * min or min
    max = vmax ~= nil and vmax * max or max

    for i = 0, data.size-1 do
        out.arr[i] = clip((data.arr[i] - min) / (max - min))
    
    return out

function cmaps.gray(data)
    local out = alloc.create_array(data.shape, 'ubyte')
    for i = 0, data.size-1 do
        out.arr[i] = math.floor(255 * data.arr[i])
    
    return out

function cmaps.gray_r(data)
    local out = alloc.create_array(data.shape, 'ubyte')
    for i = 0, data.size-1 do
        out.arr[i] = 255 - math.floor(255 * data.arr[i])
    
    return out
]#
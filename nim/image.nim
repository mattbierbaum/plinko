#[
  For bl modes, there are color channels and alpha channels, which can be treated
  differently. In the color channels, a is the active layer (above) and b is the
  background layer (below).

  http://www.pegtop.net/delphi/articles/blmodes/softlight.htm
  https://en.wikipedia.org/wiki/Bl_modes
  https://en.wikipedia.org/wiki/Alpha_compositing
]#

import array2d

import std/lenientops
import std/math

type BlendFunction* = proc(a: float, b: float): float
type NormFunction* = proc(data: seq[float]): seq[float]
type CmapFunction* = proc(data: seq[float]): seq[uint8]

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

proc hist*(arr: seq[float], nbins: int, docut: bool = true): seq[float] =
    let (min, max) = arr.minmax_cut()
    var bins: seq[float] = newSeq[float](nbins+1)
    let norm = 1.0 / (max - min)

    for i, v in arr:
        if docut and v > min:
            let g: int = floor(nbins*(v - min)*norm).int
            let n: int = bins.clamp_index(g)
            bins[n] = bins[n] + 1.0
    return bins

proc cdf*(data: seq[float]): seq[float] =
    var arr: seq[float] = newSeq[float](data.len)
    var total = 0.0
    var tsum = data.sum()

    for i, v in data:
        total = total + v
        arr[i] = total / tsum
    return arr

proc eq_hist*(data: seq[float], nbins: int=256*256): seq[float] =
    let (min, max) = data.minmax_cut()

    let df = cdf(hist(data, nbins))
    let dx = (max - min) / nbins

    proc bincenter(i: int): float =
        return min + dx/2 + i*dx
    
    let b0 = bincenter(0)
    let b1 = bincenter(nbins)

    var arr = newSeq[float](data.len)
    for i, v in data:
        if v <= b0: arr[i] = 0.0 
        if v >= b1: arr[i] = 1.0 
        if v > b0 and v < b1:
            let bin = math.floor((v - b0)/dx).int
            let x1 = bincenter(bin)
            let x2 = bincenter(bin+1)
            let y1 = df[bin]
            let y2 = df[bin+1]
            arr[i] = y1 + (y2 - y1)/(x2 - x1) * (v - x1)
    return arr

proc clip*(data: seq[float], vmin: float=1.0, vmax: float=1.0): seq[float] =
    var arr = newSeq[float](data.len)
    var (min, max) = data.minmax()

    min = vmin * min
    max = vmax * max

    for i, v in data:
        arr[i] = clip((v - min) / (max - min))
    return arr

proc gray*(data: seq[float]): seq[uint8] =
    var arr = newSeq[uint8](data.len)
    for i, v in data:
        arr[i] = math.floor(255 * v).uint8
    return arr

proc gray_r*(data: seq[float]): seq[uint8] =
    var arr = newSeq[uint8](data.len)
    for i, v in data:
        arr[i] = 255 - math.floor(255 * v).uint8
    return arr
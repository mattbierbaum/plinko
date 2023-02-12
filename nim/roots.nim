import std/math

proc sign(x: float): float =
    return (if x > 0: 1 else: -1)

let sort_networks: seq[seq[array[2, int]]] = @[
    @[[0,0]],
    @[[0,1]],
    @[[1,2], [0,2], [0,1]],
    @[[0,1], [2,3], [0,2], [1,3], [1,2]],
    @[[0,1], [3,4], [2,4], [2,3], [1,4], [0,3], [0,2], [1,3], [1,2]],
]

proc cswap(arr: var seq[float], i0: int, i1: int) =
    if arr[i0] > arr[i1]:
        let t = arr[i0]
        arr[i0] = arr[i1]
        arr[i1] = t

proc sort(arr: var seq[float]): seq[float] =
    if len(arr) <= len(sort_networks):
        let network = sort_networks[len(arr)-1]
        for i, inds in network:
            cswap(arr, inds[0], inds[1])
        return arr
    else:
        return arr.sort()

proc linear*(poly: seq[float]): seq[float] =
    return @[-poly[1] / poly[0]]

proc quadratic*(poly: seq[float]): seq[float] =
    let a = poly[2]
    let b = poly[1]
    let c = poly[0]

    if a == 0:
        if b == 0:
            return @[NaN, NaN]
        return @[-c / b, NaN]

    let desc = b*b - 4*a*c
    if desc < 0:
        return @[NaN, NaN]

    let x1 = (-b - sign(b) * sqrt(desc)) / (2*a)
    let x2 = c / (a * x1)
    var roots: seq[float] = @[x1, x2]
    return sort(roots)

proc cubic*(poly: seq[float]): seq[float] =
    let a = poly[3]
    let b = poly[2]
    let c = poly[1]
    let d = poly[0]
    let a2 = a*a
    let b2 = b*b
    let s = b / (3*a)
    let p = (3*a*c - b2) / (3*a2)
    let q = (2*b2*b - 9*a*b*c + 27*a2*d) / (27*a2*a)

    let p3 = p*p*p
    let q2 = q*q

    # there are three real roots
    if 4*p3 + 27*q2 <= 0:
        let sqrtp3 = sqrt(-p/3)
        let arg = 1/3 * arccos((3*q)/(2*p) / sqrtp3)
        let pre = 2 * sqrtp3
        let ang = 2 * PI / 3

        let t0 = pre * math.cos(arg + ang * 0)
        let t1 = pre * math.cos(arg + ang * 1)
        let t2 = pre * math.cos(arg + ang * 2)

        let x0 = t0 - s
        let x1 = t1 - s
        let x2 = t2 - s
        var roots = @[x0, x1, x2]
        return sort(roots)
    else:
        if p < 0:
            let sqrtp3 = sqrt(-p/3)
            let arg = 1/3 * math.arccosh((-3*abs(q))/(2*p) / sqrtp3)
            let t0 = -2*sign(q)*sqrtp3*math.cosh(arg)
            let x0 = t0 - s
            return @[x0]
        elif p > 0:
            let sqrtp3 = sqrt(p/3)
            let arg = 1/3 * math.arcsinh((3*q)/(2*p) / sqrtp3)
            let t0 = -2*sqrtp3*math.sinh(arg)
            let x0 = t0 - s
            return @[x0]
    return @[]

proc cubic2*(poly: seq[float]): seq[float] =
    let a = poly[3]
    let b = poly[2]
    let c = poly[1]
    let d = poly[0]

    let A = b / a
    let B = c / a
    let C = d / a

    let Q = (3*B -  A*A)/9
    let R = (9*A*B - 27*C - 2*A*A*A)/54
    let D = Q*Q*Q + R*R

    var t: seq[float] = @[]

    if (D >= 0):
        let S = sign(R + math.sqrt(D))*math.pow(abs(R + math.sqrt(D)), (1.0/3))
        let T = sign(R - math.sqrt(D))*math.pow(abs(R - math.sqrt(D)), (1.0/3))
        let Im = abs(sqrt(3.0)*(S - T)/2)

        t.add(-A/3 + (S + T))

        if abs(Im) < 1e-15:
            t.add(-A/3 - (S + T)/2)
            t.add(-A/3 - (S + T)/2)
    else:
        let th = math.arccos(R/math.sqrt(-math.pow(Q, 3)))

        t[1] = 2*math.sqrt(-Q)*math.cos(th/3) - A/3;
        t[2] = 2*math.sqrt(-Q)*math.cos((th + 2*PI)/3) - A/3;
        t[3] = 2*math.sqrt(-Q)*math.cos((th + 4*PI)/3) - A/3;

    return sort(t)

proc brent*(f: proc(t: float):float, 
           bracket: array[2, float], 
           tol: float = 1.48e-8, 
           maxiter: int = 500, 
           disp: int): float =
    let mintol = 1.0e-11
    let cg = 0.3819660
    var xmin: float = 0
    var fval: float = 0
    var iter: int = 0

    var xa: float = bracket[0]
    var xb: float = (bracket[0] + bracket[1])/2
    var xc: float = bracket[1]
    var fb: float = f(xb)
    var funcalls = 3
    var a: float = 0
    var b: float = 0

    var x = xb
    var w = xb
    var v = xb
    var fw = fb
    var fv = fb
    var fx = fb
    if xa < xc:
        a = xa
        b = xc
    else:
        a = xc
        b = xa
    var deltax = 0.0
    iter = 0

    #if disp > 2:
        #print(" ")
        #print(f"{'Func-count':^12} {'x':^12} {'f(x)': ^12}")
        #print(f"{funcalls:^12g} {x:^12.6g} {fx:^12.6g}")

    while iter < maxiter:
        var rat: float = 0
        var u: float = 0
        var fu: float = 0
        let tol1 = tol * abs(x) + mintol
        let tol2 = 2.0 * tol1
        let xmid = 0.5 * (a + b)
        if abs(x - xmid) < (tol2 - 0.5 * (b - a)):
            break
        if (abs(deltax) <= tol1):
            if (x >= xmid):
                deltax = a - x
            else:
                deltax = b - x
            rat = cg * deltax
        else:
            var tmp1 = (x - w) * (fx - fv)
            var tmp2 = (x - v) * (fx - fw)
            var p = (x - v) * tmp2 - (x - w) * tmp1
            tmp2 = 2.0 * (tmp2 - tmp1)
            if (tmp2 > 0.0):
                p = -p
            tmp2 = abs(tmp2)
            var dx_temp = deltax
            var deltax = rat
            if ((p > tmp2 * (a - x)) and (p < tmp2 * (b - x)) and
                (abs(p) < abs(0.5 * tmp2 * dx_temp))):
                rat = p * 1.0 / tmp2
                u = x + rat
                if ((u - a) < tol2 or (b - u) < tol2):
                    if xmid - x >= 0:
                        rat = tol1
                    else:
                        rat = -tol1
            else:
                if (x >= xmid):
                    deltax = a - x
                else:
                    deltax = b - x
                rat = cg * deltax

        if (abs(rat) < tol1):
            if rat >= 0:
                u = x + tol1
            else:
                u = x - tol1
        else:
            u = x + rat
        fu = f(u)
        funcalls = funcalls + 1

        if (fu > fx):
            if (u < x):
                a = u
            else:
                b = u

            if (fu <= fw) or (w == x):
                v = w
                w = u
                fv = fw
                fw = fu
            elif (fu <= fv) or (v == x) or (v == w):
                v = u
                fv = fu
        else:
            if (u >= x):
                a = x
            else:
                b = x
            v = w
            w = x
            x = u
            fv = fw
            fw = fx
            fx = fu

        # if disp > 2:
        #     print(f"{funcalls:^12g} {x:^12.6g} {fx:^12.6g}")

        iter = iter + 1

    xmin = x
    fval = fx
    iter = iter
    funcalls = funcalls
    return xmin

proc roots*(poly: seq[float]): seq[float] =
    let N = len(poly)

    if N == 1:
        return linear(poly)
    elif N == 2:
        return quadratic(poly)
    elif N == 3:
        return cubic(poly)

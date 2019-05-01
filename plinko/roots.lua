local sqrt = math.sqrt

local function sign(x)
    return x > 0 and 1 or -1
end

local sort_networks = {
    {},
    {{1,2}},
    {{2,3}, {1,3}, {1,2}},
    {{1,2}, {3,4}, {1,3}, {2,4}, {2,3}},
    {{1,2}, {4,5}, {3,5}, {3,4}, {2,5}, {1,4}, {1,3}, {2,4}, {2,3}},
}

local function cswap(arr, i0, i1)
    if arr[i0] > arr[i1] then
        local t = arr[i0]
        arr[i0] = arr[i1]
        arr[i1] = t
    end
end

local function sort(arr)
    if #arr <= #sort_networks then
        local network = sort_networks[#arr]
        for i = 1, #network do
            local inds = network[i]
            cswap(arr, inds[1], inds[2])
        end
        return arr
    else
        return arr.sort()
    end
end

local function arccosh(x)
    return math.log(x + sqrt(x*x - 1))
end

local function arcsinh(x)
    return math.log(x + sqrt(x*x + 1))
end

local function first_root(roots)
    if not roots then return nil end

    for i = 1, #roots do
        if roots[i] >= 0 and roots[i] <= 1 then
            return roots[i]
        end
    end
    return nil
end

local function quadratic(poly)
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

    local x1 = (-b - sign(b) * sqrt(desc)) / (2*a)
    local x2 = c / (a * x1)
    return sort({x1, x2})
end

local function cubic(poly)
    local a, b, c, d = poly[4], poly[3], poly[2], poly[1]
    local a2 = a*a
    local b2 = b*b
    local s = b / (3*a)
    local p = (3*a*c - b2) / (3*a2)
    local q = (2*b2*b - 9*a*b*c + 27*a2*d) / (27*a2*a)

    local p3 = p*p*p
    local q2 = q*q

    -- there are three real roots
    if 4*p3 + 27*q2 <= 0 then
        local sqrtp3 = sqrt(-p/3)
        local arg = 1/3 * math.acos((3*q)/(2*p) / sqrtp3)
        local pre = 2 * sqrtp3
        local ang = 2 * math.pi / 3

        local t0 = pre * math.cos(arg + ang * 0)
        local t1 = pre * math.cos(arg + ang * 1)
        local t2 = pre * math.cos(arg + ang * 2)

        local x0 = t0 - s
        local x1 = t1 - s
        local x2 = t2 - s
        return sort({x0, x1, x2})
    else
        if p < 0 then
            local sqrtp3 = sqrt(-p/3)
            local arg = 1/3 * arccosh((-3*math.abs(q))/(2*p) / sqrtp3)
            local t0 = -2*sign(q)*sqrtp3*math.cosh(arg)
            local x0 = t0 - s
            return {x0}
        elseif p > 0 then
            local sqrtp3 = sqrt(p/3)
            local arg = 1/3 * arcsinh((3*q)/(2*p) / sqrtp3)
            local t0 = -2*sqrtp3*math.sinh(arg)
            local x0 = t0 - s
            return {x0}
        end
    end
end

local function cubic2(poly)
	local a = poly[4]
	local b = poly[3]
	local c = poly[2]
	local d = poly[1]

	local A = b / a
	local B = c / a
	local C = d / a

    local Q = (3*B -  A*A)/9
    local R = (9*A*B - 27*C - 2*A*A*A)/54
    local D = Q*Q*Q + R*R

    local t = {}

    if (D >= 0) then
        local S = sign(R + math.sqrt(D))*math.pow(math.abs(R + math.sqrt(D)),(1/3))
        local T = sign(R - math.sqrt(D))*math.pow(math.abs(R - math.sqrt(D)),(1/3))
        local Im = math.abs(sqrt(3)*(S - T)/2)

        t[1] = -A/3 + (S + T)

        if math.abs(Im) < 1e-15 then
            t[2] = -A/3 - (S + T)/2
            t[3] = -A/3 - (S + T)/2
        end
    else
        local th = math.acos(R/math.sqrt(-math.pow(Q, 3)))

        t[1] = 2*math.sqrt(-Q)*math.cos(th/3) - A/3;
        t[2] = 2*math.sqrt(-Q)*math.cos((th + 2*math.pi)/3) - A/3;
        t[3] = 2*math.sqrt(-Q)*math.cos((th + 4*math.pi)/3) - A/3;
    end

    return sort(t)
end

local solvers = {linear, quadratic, cubic, generic}

if not math.cosh then
    math.cosh = function(x) return (math.exp(x) + math.exp(-x)) / 2 end
    math.sinh = function(x) return (math.exp(x) - math.exp(-x)) / 2 end
end

local function roots(poly)
    local N = #poly - 1

    if N == 1 then
        return linear(poly)
    elseif N == 2 then
        return quadratic(poly)
    elseif N == 3 then
        return cubic(poly)
    elseif N == 4 then
        return generic(poly)
    end
end

return {
    quadratic=quadratic,
    cubic=cubic,
    first_root=first_root,
    roots=roots
}

local P = require('plinko')

function benchmark(func)
    local t_start = os.clock()
    local name, steps = func()
    local t_end = os.clock()
    local time = t_end - t_start
    local out = string.format(
        '%0.2f million steps per second (%0.2f seconds)',
        (steps / time / 1e6), time
    )
    print(name, out)
end

function vector_creation()
    local sum = 0.0
    local steps = 1e8
    for i = 0, steps do
        local v = {0.0, 1.0*i/steps}
        sum = sum + v[2]
    end
    return "vector_creation", steps
end

function vector_modification()
    local sum = 0.0
    local steps = 1e8
    for i = 0, steps do
        local v = {0.0, 1.0*i/steps}
        sum = sum + v[2]
    end
    return "vector_modification", steps
end

function segment_creation()
    local sum = 0.0
    local steps = 5e6
    for i = 0, steps do
        local s = P.objects.Segment({0.0, 1.0*i/steps}, {0.0, 0.0})
        sum = sum + s.p0[2]
    end
    return "segment_creation", steps
end

function roots_quadratic()
    local sum = 0.0
    local steps = 1e6
    local v = {-1.0, -1.0, 1.0}
    for i = 0, steps do
        sum = sum + P.roots.roots(v)[1]
    end
    return "roots_quadratic", steps
end

function circle_intersection()
    local sum = 0.0
    local steps = 1e6
    local c = P.objects.Circle({0.0, 0.0}, 0.5)
    local s = P.objects.Segment({0.0, 0.0}, {1.0, 1.0})
    for i = 0, steps do
        local o, t = c:intersection(s)
        sum = sum + t
    end
    return "circle_intersection", steps
end

benchmark(vector_creation)
benchmark(vector_modification)
benchmark(segment_creation)
benchmark(roots_quadratic)
benchmark(circle_intersection)
local modules = {
    'alloc', 'forces', 'ics', 'image', 'interrupts', 'neighborlist', 'objects',
    'observers', 'plotting', 'roots', 'simulation', 'util', 'vector'
}

local package = {}
for i, mod in pairs(modules) do
    package[mod] = require('plinko.'..mod)
end

function package.run_file(filename)
    local f = assert(loadfile(filename))
    return f()
end

function package.run_string(string)
    return loadstring(string)()
end

return package

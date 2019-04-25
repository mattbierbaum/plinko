local modules = {
    'alloc', 'forces', 'ics', 'image', 'interrupts', 'neighborlist', 'objects',
    'observers', 'plotting', 'roots', 'simulation', 'util', 'vector'
}

local package = {}
for i, mod in pairs(modules) do
    package[mod] = require('plinko.'..mod)
end

return package

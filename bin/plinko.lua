local argparse = require('lib.argparse')
local plinko = require('plinko')

local prefix = 'bundle'
local scripts = {}
local scripts_max = 0
local scripts_string = ''

if _G.bundle_names then
    for i, name in pairs(_G.bundle_names) do
        if string.find(name, prefix .. '.') then
            local n = string.gsub(name, prefix .. '%.(.-)', '%1')
            scripts[#scripts + 1] = n

            if string.len(n) > scripts_max then
                scripts_max = string.len(n)
            end
        end
    end

    scripts_max = scripts_max + 4
    local columns = math.floor(80 / scripts_max)

    local c = 0
    local out = ''

    table.sort(scripts)
    for i,  name in pairs(scripts) do
        local n = string.len(name)
        local t = name

        for j = 1, scripts_max - n - 2 do
            t = t .. ' '
        end

        if c == columns and i ~= #scripts then
            t = t .. '\n'
        end

        scripts_string = scripts_string .. t

        if c > columns-1 then
            c = 0
        else
            c = c + 1
        end
    end
end

local name = 'plinko'
local version = 'v1.0.0'

local desc = [[
Generative art based on an episode of The Price Is Right in which Snoop Dogg
plays Plinko. Examples and scripts are primarily based on that physical
scenario though the framework is flexible enough to simulate many types of
dynamics.
]]

local epilog = [[
See examples, wiki, etc at github.com/mattbierbaum/plinko.
]]

local help_run = [[Run a script from the filesystem or stdin.]]
local epil_run = [[
The recommended format of the script is:

===============================================================================
local P = require('plinko')
local box = P.objects.Box({0, 0}, {1, 1})
local conf = {
    objects = {box},
    forces = {P.forces.generate_force_central({0.5, 0.5}, 9.0)},
    particles = {P.objects.SingleParticle({0.63, 0.63}, {1.5, 1.3}, {0, 0})},
    observers = {P.observers.SVGLinePlot('freeparticle.svg', box, 1e-5)}
}
P.ics.create_simulation(conf):step(1e4)
===============================================================================
]]

local help_exec = [[Execute a script distributed with plinko.]]
local epil_exec = ([[
The names of available embedded scripts are:

===============================================================================
%s
===============================================================================
]]):format(scripts_string)

local parser = argparse()
    :name(name)
    :description(desc)
    :epilog(epilog)

parser:command_target('command')
parser:help_description_margin(30)
parser:help_max_width(80)
parser:flag('-v --version', 'Print version information and exit.')

local crun = parser:command('run r', help_run, epil_run)
local cexec = parser:command('exec e', help_exec, epil_exec)

crun:argument('script', 'Filename of script to run, "-" for stdin.')
crun:argument('options', 'Command line arguments to the script. Must be preceeded by "--" to indicate that all following options are passed to the other script.'):args('*')
cexec:argument('script', 'Name of the script to run.')
cexec:argument('options', 'Command line arguments to the script. Must be preceeded by "--" to indicate that all following options are passed to the embedded script.'):args('*')

local opts = parser:parse()
local args = opts.options or {}
args[-1] = _G.arg[-1]
args[0] = opts.script
_G.arg = args

if opts.command == 'run' then
    plinko.run_file(opts.script)
elseif opts.command == 'exec' then
    require(prefix .. '.' .. opts.script)
end

local observers = require('plinko.observers')
local plotting = require('plinko.plotting')

local cli = {}

local function extension(filename)
    return filename:match("^.+%.(.+)$")
end

local function convert_seed(str)
    local seed = tonumber(str)
    math.randomseed(seed)
    return seed
end

function cli.options_seed(arg, seed)
    arg:option('--seed', 'Random seed')
       :convert(convert_seed)
       :default(seed)
       :argname('seed')
end

function cli.options_observer(arg, filename, res)
    arg:help_max_width(80)
    arg:group('Output options',
        arg:option('-r --res',
                'Image resolution, ratio of image size to line width. ' ..
                'For pgm, this is the resolution, svg is the relative linewidth'
           )
           :convert(tonumber)
           :default(res)
           :argname('res'),

        arg:option('-o --out',
                'Filename for output, where extension determines file type. ' ..
                'Extensions can be one of (svg, csv, pgm).'
           )
           :default(filename)
           :argname('filename')
    )
end

function cli.args_to_observer(arg, box)
    local filename = arg.out
    local ext = extension(filename)
    local res = arg.res

    local width = box.uu[1] - box.ll[1]
    if ext == 'svg' then
        return observers.SVGLinePlot(filename, box, 1.0/res/width/5)
    elseif ext == 'csv' then
        return observers.StateFileRecorder(filename)
    elseif ext == 'pgm' then
        return observers.ImageRecorder(
            filename, plotting.DensityPlot(box, res/width, 'pgm5')
        )
    else
        print('File extension must be one of (svg, pgm, csv)')
        os.exit()
    end
end

return cli

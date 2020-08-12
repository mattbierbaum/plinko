local observers = require('plinko.observers')
local plotting = require('plinko.plotting')
local image = require('plinko.image')
local util = require('plinko.util')

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
        arg:option('-o --out',
                'Filename for output, where extension determines file type. ' ..
                'Extensions can be one of (svg, csv, pgm).'
           )
           :default(filename)
           :argname('filename'),

        arg:option('-r --res',
                'Image resolution, ratio of image size to line width. ' ..
                'For pgm, this is the resolution, svg is the relative linewidth'
           )
           :convert(tonumber)
           :default(res)
           :argname('res'),

        arg:option('--cmap',
                'Name of the color map with which to tone the image. Options are: ' ..
                table.concat(util.table_keys(image.cmaps), ', ')
            )
            :default('gray_r')
            :argname('cmap'),

        arg:option('--norm',
                'Name of the normalization procedure. Options are: ' ..
                table.concat(util.table_keys(image.norms), ', ')
            )
            :default('eq_hist')
            :argname('norm'),

        arg:option('--clip',
                'The clipping value for norm=clip, in the format %f,%f where each value ' ..
                'is a multiplicative factor of the true density range. Examples: "nil,0.1" "0.1,1"'
            )
            :default('nil,nil')
            :argname('clip')
            :convert(util.tovec),
        arg:option('--blendmode',
                'The blend mode for adding colors when generating density plots. Options are: ' ..
                table.concat(util.table_keys(image.blendmodes), ', ')
            )
            :default('additive')
            :argname('blendmode')
    )
end

function cli.args_to_observer(arg, box)
    local filename = arg.out
    local ext = extension(filename)
    local res = arg.res

    local clip = arg.clip
    local blend = nil
    local cmap = nil
    local norm = nil

    if arg.norm == 'eq_hist' then
        norm = image.norms.eq_hist
    elseif arg.norm == 'clip' then
        norm = function(d) return image.norms.clip(d, clip[1], clip[2]) end
    else
        print('Provided norm function doesnt match available options')
        os.exit()
    end

    if image.cmaps[arg.cmap] ~= nil then
        cmap = image.cmaps[arg.cmap]
    else
        print('Provided cmap function doesnt match available options')
        os.exit()
    end

    if image.blendmodes[arg.blendmode] ~= nil then
        blend = image.blendmodes[arg.blendmode]
    else
        print('Provided blendmode function doesnt match available options')
        os.exit()
    end

    local width = box.uu[1] - box.ll[1]
    if ext == 'svg' then
        return observers.SVGLinePlot(filename, box, 1.0/res/width/5)
    elseif ext == 'csv' then
        return observers.StateFileRecorder(filename)
    elseif ext == 'pgm' then
        return observers.ImageRecorder(
            filename, plotting.DensityPlot(box, res/width, blend), 'pgm5',
            {cmap=cmap, norm=norm}
        )
    else
        print('File extension must be one of (svg, pgm, csv)')
        os.exit()
    end
end

return cli

local sdl = require('sdl2')
local ffi = require('ffi')
local bit = require('bit')

local ics = require('ics')
local forces = require('forces')
local objects = require('objects')
local observers = require('observers')
local util = require('util')

local size = 600
local movementFactor = 15
local lastEnemyPos = 50
local window, renderer, playerPos, topBar, bottomBar

ImageRecorder = util.class(observers.Observer)
function ImageRecorder:init(r, w, h)
    self.r = r
    self.w = w
    self.h = h
    self.lastposition = nil
end
function ImageRecorder:begin() self.lastposition = nil end
function ImageRecorder:reset() self.lastposition = nil end

function ImageRecorder:update_particle(particle)
    if self.lastposition then
        --print(particle.pos[1], particle.pos[2])
        sdl.renderDrawLine(
            self.r,
            self.lastposition[1], self.h - self.lastposition[2],
            particle.pos[1], self.h - particle.pos[2]
        )
        self.lastposition[1] = particle.pos[1]
        self.lastposition[2] = particle.pos[2]
    else
        self.lastposition = {particle.pos[1], particle.pos[2]}
    end
end

function create_simulation(w, h)
    local conf = {
        dt = 1e-1,
        eps = 1e-4,
        forces = {forces.force_gravity},
        particles = {
            objects.SingleParticle({0.51*w, 0.91*h}, {0.01, 0.0111*h}, {0, 0})
            --objects.UniformParticles({1, 1}, {1, 1}, {20, 20}, {10, 20}, 1000)
        },
        objects = {
            objects.Box({0, 0}, {w, h}),
            objects.BezierCurve({{0, 0}, {0, h}, {w, h}, {w, 0}}),
            objects.BezierCurve({{0, 0}, {w, h}, {0, h}, {w, 0}}),
        },
        observers = {
            ImageRecorder(renderer, w, h),
            --observers.StateFileRecorder('./test.csv'),
            --observers.TimePrinter(1e5)
        },
    }
    
    return ics.create_simulation(conf)
end

function run()
    local loop = false

    while loop do
        local e = ffi.new('SDL_Event')

        while sdl.pollEvent(e) ~= 0 do
            if e.type == sdl.QUIT then
                loop = false
            elseif e.type == sdl.KEYDOWN then
                --[[if e.key.keysym.sym then
                switch ( event.key.keysym.sym )
                {
                    case SDLK_RIGHT:
                        playerPos.x += movementFactor;
                        break;
                    case SDLK_LEFT:
                        playerPos.x -= movementFactor;
                        break;
                        // Remeber 0,0 in SDL is left-top. So when the user pressus down, the y need to increase
                    case SDLK_DOWN:
                        playerPos.y += movementFactor;
                        break;
                    case SDLK_UP:
                        playerPos.y -= movementFactor;
                        break;
                    default :
                        break;
                }]]
            end
        end

        --render()

        sdl.delay(16)
    end

    render()
    sdl.delay(10000)
end

function render()
    local s = create_simulation(size, size)

    local rect = ffi.new('SDL_Rect')
    rect.x = 0
    rect.y = 0
    rect.w = 50
    rect.h = 50
    --sdl.renderFillRect(renderer, rect)

    sdl.setRenderDrawColor(renderer, 255, 255, 255, 255)
    sdl.renderClear(renderer)
    sdl.setRenderDrawColor(renderer, 0, 0, 0, 30)

    for i = 1, 1000 do
        local t_start = os.clock()
        s:step(1e3)
        sdl.renderPresent(renderer)
        local t_end = os.clock()
    end
end

function InitEverything()
    if not init() then
        return false
    end
    SetupRenderer()
    return true
end

function init()
    if sdl.init(sdl.INIT_EVERYTHING) < 0 then
        return false
    end

    window = sdl.createWindow(
        "Jamba juice",
        sdl.WINDOWPOS_CENTERED,
        sdl.WINDOWPOS_CENTERED,
        size, size,
        sdl.WINDOW_SHOWN
    )
    if not window then
        print("Failed to create window")
        return false
    end

    renderer = sdl.createRenderer(window, -1,
        bit.bor(sdl.RENDERER_ACCELERATED, sdl.RENDERER_PRESENTVSYNC)
    )
    sdl.setRenderDrawBlendMode(renderer, sdl.BLENDMODE_BLEND)

    if not renderer then
        print("Failed to create renderer")
        return false
    end
    return true
end

function SetupRenderer()
    sdl.renderSetLogicalSize(renderer, size, size)
end

function main()
    if not InitEverything() then
        return -1
    end

    run()
end

main()

local sdl = require 'sdl2'
local ffi = require 'ffi' 

local SCREEN_WIDTH = 640
local SCREEN_HEIGHT = 480

local gWindow = nil
local gScreenSurface = nil
local gHelloWorld = nil

function init()
    if sdl.init(sdl.INIT_VIDEO) < 0 then
        print('SDL_INIT failed!')
        return false
    end

    gWindow = sdl.createWindow(
        "Jamba juice",
        sdl.WINDOWPOS_CENTERED, 
        sdl.WINDOWPOS_CENTERED, 
        SCREEN_WIDTH, 
        SCREEN_HEIGHT,
        sdl.WINDOW_SHOWN
    )
    if not gWindow then
        return false
    end
    gScreenSurface = sdl.getWindowSurface(gWindow)
    return true
end

function loadMedia()
    print('hi')
    gHelloWorld = sdl.loadBMP('example_merged.bmp')
    if not gHelloWorld then
        print('Unable to load File')
        return false
    end
    return true
end

function close()
    sdl.freeSurface( gHelloWorld )
    gHelloWorld = nil
    
    sdl.destroyWindow(gWindow)
    gWindow = nil
    
    sdl.quit()
end

function main()
    if not init() then
        print 'failed to initialize'
        return
    end
    if not loadMedia() then
        print 'failed to load media'
        return
    end
    local quit = false
    local e = ffi.new('SDL_Event')
    sdl.blitSurface(gHelloWorld, nil, gScreenSurface, nil)
    sdl.updateWindowSurface(gWindow)
    
    while not quit do
        while sdl.pollEvent(e) ~= 0 do
            if e.type == sdl.QUIT then
                quit = true
            end
        end
    end
    close()
end
main()

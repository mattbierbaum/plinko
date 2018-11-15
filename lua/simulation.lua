local json = require('dkjson')
local util = require('util')
local vector = require('vector')
local objects = require('objects')
local forces = require('forces')
local neighborlist = require('neighborlist')

Simulation = util.class()
function Simulation:init(dt)
    self.t = 0
    self.dt = dt
    self.objects = {}
    self.particles = {}
    self.force_func = {}

    self.nbl = neighborlist.NaiveNeighborlist()
end

function Simulation:add_object(obj)
    self.objects[#self.objects + 1] = obj
end

function Simulation:add_particle(particle)
    self.particles[#self.particles + 1] = particle
end

function Simulation:add_force(func)
    self.force_func[#self.force_func + 1] = func
end

function Simulation:set_neighborlist(nbl)
    self.nbl = nbl
    for i = 1, #self.objects do
        self.nbl:append(self.objects[i])
    end
    self.nbl:calculate()
end

function Simulation:dump_trajectory(p)
    local txt = json.encode(p, {indent=true})
    local file = io.open('./test.json', 'w')
    file:write(txt)
end

function Simulation:intersection_bruteforce(seg)
    local mint = 2
    local mino = nil

    for ind = 1, #self.objects do
        local obj = self.objects[ind]
        local o, t = obj:intersection(seg)
        if t and t < mint and t <= 1 and t > 0 then
            mint = t
            mino = o
        end
    end

    return mint, mino
end

function Simulation:intersection(seg)
    local mint = 2
    local mino = nil

    local neighs = self.nbl:near(seg)
    for ind = 1, #neighs do
        local obj = neighs[ind]
        local o, t = obj:intersection(seg)
        if t and t < mint and t <= 1 and t > 0 then
            mint = t
            mino = o
        end
        --print('============')
        --util.tprint(seg0)
        --util.tprint(obj)
        --util.tprint(t)
    end

    return mint, mino
end

function Simulation:linear_propagation(part0, part1)

end

function Simulation:step(steps)
    local px = {}
    local py = {}
    --local save = 0
    --px[steps] = 1
    --py[steps] = 1

    local steps = steps or 1
    local seg0 = objects.Segment({0, 0}, {0, 0})
    local seg1 = objects.Segment({0, 0}, {0, 0})
    local part0 = objects.PointParticle()
    local part1 = objects.PointParticle()

    local time = 0
    local EPS = 1e-8
    local mint = 2
    local mino = nil
    local vel = {0, 0}

    for step = 1, steps do
        self.force_func[1](self.particles)

        for particle = 1, #self.particles do 
            part0 = self.particles[particle]
            forces.integrate_euler(part0, part1, self.dt)

            vel = part1.vel
            vector.copy(part0.pos, seg0.p0)
            vector.copy(part1.pos, seg0.p1)

            local q = #px + 1
            px[q] = part0.pos[1]
            py[q] = part0.pos[2]

            for collision = 1, 10 do
                local mint1, mino1 = self:intersection(seg0)
                local mint, mino = self:intersection_bruteforce(seg0)

                --print(mino, mino1)
                if not (mino == mino1) then
                    print('*')
                    util.tprint(mino1)
                    util.tprint(mino)
                    print(mint1, mint)
                    util.tprint(part0)
                    util.tprint(part1)
                    return
                end

                if not mino then
                    break
                end

                mint = (1 - EPS) * mint
                time = time + (1 - time)*mint

                seg1.p0 = seg0.p1
                seg1.p1 = vector.lerp(seg0.p0, seg0.p1, mint)

                local q = #px + 1
                px[q] = seg1.p1[1]
                py[q] = seg1.p1[2]

                local norm = mino:normal(seg1)
                local dir = vector.reflect(vector.vsubv(seg0.p1, seg1.p1), norm)

                seg0.p0 = seg1.p1
                seg0.p1 = vector.vaddv(seg1.p1, dir)
                vel = vector.reflect(vel, norm)
            end

            vector.copy(seg0.p1, part0.pos)
            vector.copy(vel, part0.vel)
        end
    end

    self:dump_trajectory({px, py})
end

return {Simulation=Simulation}

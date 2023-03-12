import particles
import vector

type IndependentForce* = proc(particle: PointParticle): Vec
type Integrator* = proc(particle: PointParticle, dt: float): PointParticle

proc generate_force_gravity*(g: float = -1.0): IndependentForce =
    let f: IndependentForce = proc(particle: PointParticle): Vec =
        return [0.0, g]
    return f

proc generate_force_central*(c: Vec, k: float): IndependentForce =
    let f: IndependentForce = proc(particle: PointParticle): Vec =
        return k * (c - particle.pos)
    return f

proc force_none*(particle: PointParticle): Vec =
    result = [0.0, 0.0]

proc integrate_euler*(p0: PointParticle, dt: float): PointParticle =
    var p1 = PointParticle().copy(p0)
    p1.vel = p0.vel + p0.acc * dt
    p1.pos = p0.pos + p1.vel * dt
    return p1

proc integrate_midpoint*(p0: PointParticle, dt: float): PointParticle =
    var p1 = PointParticle().copy(p0)
    p1.vel = p0.vel + p0.acc * dt
    p1.pos = p0.pos + 0.5*(p0.vel + p1.vel) * dt
    return p1

proc integrate_velocity_verlet*(p0: PointParticle, dt: float): PointParticle =
    # x1 = x0 + v0*dt + 1/2 * a0 * dt*dt
    # v1 = v0 + 1/2 (a1 + a0) * dt
    var p1 = PointParticle().copy(p0)
    p1.pos = p0.pos + p0.vel * dt + 0.5 * p0.acc * dt * dt
    p1.vel = p0.vel + p0.acc * dt
    return p1

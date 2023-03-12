import ../interrupts
import ../objects
import ../observers
import ../particles

import std/unittest

suite "interrupt tests":
    test "max_collisions 1":
        let obj = Circle().initCircle(pos=[0.0,0.0], rad=1.0, name="circle")
        let counter = MaxCollisions().initMaxCollisions(max=1)
        let p = PointParticle().initPointParticle(pos=[0.0,0.99])
        check(counter.is_triggered_particle(p) == false)

        counter.update_collision(p, obj, 0.0)
        check(counter.is_triggered_particle(p) == true)
        check(counter.is_triggered() == true)

        counter.update_collision(p, obj, 0.0)
        check(counter.is_triggered_particle(p) == true)

    test "max_collisions 3":
        let obj = Circle().initCircle(pos=[0.0,0.0], rad=1.0, name="circle")
        let counter = MaxCollisions().initMaxCollisions(max=3)
        let p = PointParticle().initPointParticle(pos=[0.0,0.99])
        check(counter.is_triggered_particle(p) == false)

        counter.update_collision(p, obj, 0.0)
        check(counter.is_triggered() == false)
        check(counter.is_triggered_particle(p) == false)

        counter.update_collision(p, obj, 0.0)
        check(counter.is_triggered() == false)
        check(counter.is_triggered_particle(p) == false)

        counter.update_collision(p, obj, 0.0)
        check(counter.is_triggered() == true)
        check(counter.is_triggered_particle(p) == true)

    test "max_collisions multiple":
        let obj = Circle().initCircle(pos=[0.0,0.0], rad=1.0, name="circle")
        let counter = MaxCollisions().initMaxCollisions(max=1)
        let p0 = PointParticle().initPointParticle(pos=[0.0,0.99], index=0)
        let p1 = PointParticle().initPointParticle(pos=[0.0,0.99], index=1)
        check(counter.is_triggered() == false)
        check(counter.is_triggered_particle(p0) == false)
        check(counter.is_triggered_particle(p1) == false)

        counter.update_collision(p0, obj, 0.0)
        check(counter.is_triggered() == false)
        check(counter.is_triggered_particle(p0) == true)
        check(counter.is_triggered_particle(p1) == false)

        counter.update_collision(p1, obj, 0.0)
        check(counter.is_triggered() == true)
        check(counter.is_triggered_particle(p0) == true)
        check(counter.is_triggered_particle(p1) == true)

    test "collision 1":
        let obj = Circle().initCircle(pos=[0.0,0.0], rad=1.0, name="circle")
        let other = Circle().initCircle(pos=[0.0,0.0], rad=1.0, name="other")

        let collision = Collision().initCollision(obj=obj)
        let p0 = PointParticle().initPointParticle(pos=[0.0,0.99], index=0)
        let p1 = PointParticle().initPointParticle(pos=[0.0,0.99], index=1)
        check(collision.is_triggered() == false)
        check(collision.is_triggered_particle(p0) == false)
        check(collision.is_triggered_particle(p1) == false)

        collision.update_collision(p0, other, 0.0)
        check(collision.is_triggered() == false)
        check(collision.is_triggered_particle(p0) == false)
        check(collision.is_triggered_particle(p1) == false)

        collision.update_collision(p0, obj, 0.0)
        check(collision.is_triggered() == false)
        check(collision.is_triggered_particle(p0) == true)
        check(collision.is_triggered_particle(p1) == false)

        collision.update_collision(p1, obj, 0.0)
        check(collision.is_triggered() == true)
        check(collision.is_triggered_particle(p0) == true)
        check(collision.is_triggered_particle(p1) == true)

suite "observer groups":
    test "collision group and":
        let obj = Circle().initCircle(pos=[0.0,0.0], rad=1.0, name="circle")

        let collision = Collision().initCollision(obj=obj)
        let counter = MaxCollisions().initMaxCollisions(max=2)
        let observers: seq[Observer] = @[collision.Observer, counter.Observer]

        let group = ObserverGroup().initObserverGroup(observers=observers, op=AndOp)
        let p0 = PointParticle().initPointParticle(pos=[0.0,0.99], index=0)
        let p1 = PointParticle().initPointParticle(pos=[0.0,0.99], index=1)

        check(group.is_triggered() == false)
        check(group.is_triggered_particle(p0) == false)
        check(group.is_triggered_particle(p1) == false)

        group.update_collision(p0, obj, 0.0) 

        check(collision.is_triggered_particle(p0) == true)
        check(counter.is_triggered_particle(p0) == false)

        check(group.is_triggered() == false)
        check(group.is_triggered_particle(p0) == false)
        check(group.is_triggered_particle(p1) == false)

        group.update_collision(p0, obj, 0.0)

        check(collision.is_triggered_particle(p0) == true)
        check(counter.is_triggered_particle(p0) == true)

        check(group.is_triggered() == false)
        check(group.is_triggered_particle(p0) == true)
        check(group.is_triggered_particle(p1) == false)

        group.update_collision(p1, obj, 0.0)
        group.update_collision(p1, obj, 0.0)

        check(collision.is_triggered_particle(p1) == true)
        check(counter.is_triggered_particle(p1) == true)

        check(group.is_triggered() == true)
        check(group.is_triggered_particle(p0) == true)
        check(group.is_triggered_particle(p1) == true)

    test "collision group or":
        let obj = Circle().initCircle(pos=[0.0,0.0], rad=1.0, name="circle")

        let collision = Collision().initCollision(obj=obj)
        let counter = MaxCollisions().initMaxCollisions(max=2)
        let observers: seq[Observer] = @[collision.Observer, counter.Observer]

        let group = ObserverGroup().initObserverGroup(observers=observers, op=OrOp)
        let p0 = PointParticle().initPointParticle(pos=[0.0,0.99], index=0)
        let p1 = PointParticle().initPointParticle(pos=[0.0,0.99], index=1)

        check(group.is_triggered() == false)
        check(group.is_triggered_particle(p0) == false)
        check(group.is_triggered_particle(p1) == false)

        group.update_collision(p0, obj, 0.0) 

        check(collision.is_triggered_particle(p0) == true)
        check(counter.is_triggered_particle(p0) == false)

        check(group.is_triggered() == false)
        check(group.is_triggered_particle(p0) == true)
        check(group.is_triggered_particle(p1) == false)

        group.update_collision(p0, obj, 0.0)

        check(collision.is_triggered_particle(p0) == true)
        check(counter.is_triggered_particle(p0) == true)

        check(group.is_triggered() == false)
        check(group.is_triggered_particle(p0) == true)
        check(group.is_triggered_particle(p1) == false)

        group.update_collision(p1, obj, 0.0)

        check(collision.is_triggered_particle(p1) == true)
        check(counter.is_triggered_particle(p1) == false)

        check(group.is_triggered() == true)
        check(group.is_triggered_particle(p0) == true)
        check(group.is_triggered_particle(p1) == true)

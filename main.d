module main;

import dllmain;

//import world;
//import geom;
//import rbody;

import core.runtime;
import core.memory;
import dlib.core.memory;
import dlib.container.bst;
import dlib.math.vector;
import dlib.math.matrix;
import dlib.math.affine;
import dmech.world;
import dmech.rigidbody;
import dmech.geometry;
import dmech.shape;
import dmech.constraint;
import dmech.raycast;

__gshared int numPhysicsWorlds = 0;

double gmptr(T)(T obj)
{
    return cast(double)cast(uint)cast(void*)obj;
}

T toObject(T)(double d)
{
    return cast(T)cast(void*)cast(uint)d;
}

extern(C):

export double dmInit()
{
    version(linux) Runtime.initialize();
    GC.disable();
    return 1.0;
}

export double dmCreateWorld(double maxCollisions)
{
    PhysicsWorld world = New!PhysicsWorld(cast(uint)maxCollisions);
    numPhysicsWorlds++;
    return world.gmptr;
}

export double dmDeleteWorld(double w)
{
    PhysicsWorld world = w.toObject!(PhysicsWorld);
    if (world)
    {
        Delete(world);
        numPhysicsWorlds--;
    }
    return 1.0;
}

export double dmGetNumWorlds()
{
    return numPhysicsWorlds;
}

export double dmWorldUpdate(double w, double dt)
{
    PhysicsWorld world = w.toObject!(PhysicsWorld);
    if (world)
    {
        world.update(dt);
    }
    return 1.0;
}

export double dmWorldAddStaticBody(double w, double px, double py, double pz)
{
    PhysicsWorld world = w.toObject!(PhysicsWorld);
    if (world)
    {
        RigidBody rb = world.addStaticBody(Vector3f(px, py, pz));
        return rb.gmptr;
    }
    else
        return 0.0;
}

export double dmWorldAddDynamicBody(double w, double px, double py, double pz, double mass)
{
    PhysicsWorld world = w.toObject!(PhysicsWorld);
    if (world)
    {
        RigidBody rb = world.addDynamicBody(Vector3f(px, py, pz), mass);
        return rb.gmptr;
    }
    else
        return 0.0;
}

export double dmWorldAddCollisionShape(double w, double b, double g, double px, double py, double pz, double mass)
{
    PhysicsWorld world = w.toObject!(PhysicsWorld);
    RigidBody rb = b.toObject!(RigidBody);
    Geometry geom = g.toObject!(Geometry);
    if (world && rb && geom)
    {
        ShapeComponent sc = world.addShapeComponent(rb, geom, Vector3f(px, py, pz), mass);
        return sc.gmptr;
    }
    else
        return 0.0;
}

export double dmCreateGeomBox(double hsx, double hsy, double hsz)
{
    GeomBox geom = New!(GeomBox)(Vector3f(hsx, hsy, hsz));
    return geom.gmptr;
}

export double dmCreateGeomCylinder(double h, double r)
{
    GeomCylinder geom = New!(GeomCylinder)(h, r);
    return geom.gmptr;
}

export double dmBodyGetPosition(double b, double index)
{
    RigidBody rb = b.toObject!(RigidBody);      
    if (rb)
    {
        return rb.position.arrayof[cast(uint)index];
    }
    else
        return 0.0;
}

export double dmBodyGetDirection(double b, double index)
{
    RigidBody rb = b.toObject!(RigidBody);      
    if (rb)
    {
        Matrix4x4f m = rb.transformation;
        Vector3f dir = m.forward;
        return dir.arrayof[cast(uint)index];
    }
    else
        return 0.0;
}

export double dmBodyGetUp(double b, double index)
{
    RigidBody rb = b.toObject!(RigidBody);      
    if (rb)
    {
        Matrix4x4f m = rb.transformation;
        Vector3f u = m.up;
        return u.arrayof[cast(uint)index];
    }
    else
        return 0.0;
}

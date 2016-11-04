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
import character;
import model;

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

// World

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

export double dmWorldSetModel(double w, double m)
{
    PhysicsWorld world = w.toObject!(PhysicsWorld);
    if (m != 0.0)
    {
        Model model = m.toObject!(Model);
        if (world && model)
        {
            if (model.bvh)
            {
                world.bvhRoot = model.bvh.root;
                return 1.0;
            }
            else
                return 0.0;
        }
        else
            return 0.0;
    }
    else
    {
        world.bvhRoot = null;
        return 1.0;
    }
}

// Geometry

export double dmCreateGeomSphere(double r)
{
    GeomSphere geom = New!(GeomSphere)(r);
    return geom.gmptr;
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

export double dmCreateGeomCone(double h, double r)
{
    GeomCone geom = New!(GeomCone)(h, r);
    return geom.gmptr;
}

export double dmCreateGeomEllipsoid(double rx, double ry, double rz)
{
    GeomEllipsoid geom = New!(GeomEllipsoid)(Vector3f(rx, ry, rz));
    return geom.gmptr;
}

export double dmDeleteGeom(double g)
{
    Geometry geom = g.toObject!(Geometry);
    if (geom)
    {
        Delete(geom);
    }
    return 1.0;
}

// Body

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

// Character

export double dmCharacterCreate(double w, double g, double px, double py, double pz, double mass)
{
    PhysicsWorld world = w.toObject!(PhysicsWorld);
    Geometry geom = g.toObject!(Geometry);
    if (world && geom)
    {
        CharacterController cc = New!(CharacterController)(world, Vector3f(px, py, pz), mass, geom);
        return cc.gmptr;
    }
    else
        return 0.0;
}

export double dmCharacterCreateSensorShape(double c, double g, double px, double py, double pz)
{
    CharacterController cc = c.toObject!(CharacterController); 
    Geometry geom = g.toObject!(Geometry);
    if (cc && geom)
    {     
        ShapeComponent s = cc.createSensor(geom, Vector3f(px, py, pz));
        return s.gmptr;
    }
    else
        return 0.0;
}

export double dmCharacterGetBody(double c)
{
    CharacterController cc = c.toObject!(CharacterController); 
    if (cc)
    {     
        return cc.rbody.gmptr;
    }
    else
        return 0.0;
}

export double dmCharacterMove(double c, double dx, double dy, double dz, double speed)
{
    CharacterController cc = c.toObject!(CharacterController); 
    if (cc)
    {     
        cc.move(Vector3f(dx, dy, dz), speed);
        return 1.0;
    }
    else
        return 0.0;
}

export double dmCharacterJump(double c, double height)
{
    CharacterController cc = c.toObject!(CharacterController); 
    if (cc)
    {     
        cc.jump(height);
        return 1.0;
    }
    else
        return 0.0;
}

export double dmCharacterUpdate(double c, double clampy)
{
    CharacterController cc = c.toObject!(CharacterController); 
    if (cc)
    {     
        cc.update(cast(bool)cast(uint)clampy);
        return 1.0;
    }
    else
        return 0.0;
}

export double dmCharacterIsOnGround(double c)
{
    CharacterController cc = c.toObject!(CharacterController); 
    if (cc)
    {     
        return cc.onGround;
    }
    else
        return 0.0;
}

export double dmCharacterGetGroundPosition(double c, double index)
{
    CharacterController cc = c.toObject!(CharacterController); 
    if (cc)
    {     
        return cc.floorPosition.arrayof[cast(uint)index];
    }
    else
        return 0.0;
}

export double dmCharacterGetGroundNormal(double c, double index)
{
    CharacterController cc = c.toObject!(CharacterController); 
    if (cc)
    {     
        return cc.floorNormal.arrayof[cast(uint)index];
    }
    else
        return 0.0;
}

export double dmCharacterGetGroundBody(double c)
{
    CharacterController cc = c.toObject!(CharacterController); 
    if (cc)
    {     
        return cc.floorBody.gmptr;
    }
    else
        return 0.0;
}

// Model

export double dmModelCreate()
{
    Model m = New!(Model)();
    return m.gmptr;
}

export double dmDeleteModel(double model)
{
    Model m = model.toObject!(Model);
    if (m)
    {
        Delete(m);
    }
    return 1.0;
}

export double dmModelAddMesh(double model)
{
    Model m = model.toObject!(Model);
    if (m)
    {
        return m.addMesh();
    }
    return 1.0;
}

export double dmModelMeshAddVertex(double model, double mindex, double x, double y, double z)
{
    Model m = model.toObject!(Model);
    if (m)
    {
        return m.meshes[cast(uint)mindex].addVertex(Vector3f(x, y, z));
    }
    return 1.0;
}

export double dmModelMeshAddNormal(double model, double mindex, double x, double y, double z)
{
    Model m = model.toObject!(Model);
    if (m)
    {
        return m.meshes[cast(uint)mindex].addNormal(Vector3f(x, y, z));
    }
    return 1.0;
}

export double dmModelMeshAddFaceGroup(double model, double mindex)
{
    Model m = model.toObject!(Model);
    if (m)
    {
        return m.meshes[cast(uint)mindex].addFacegroup();
    }
    return 1.0;
}

export double dmModelMeshFaceGroupAddTriangle(double model, double mindex, double fg, double v1, double v2, double v3)
{
    Model m = model.toObject!(Model);
    if (m)
    {
        return m.meshes[cast(uint)mindex].facegroups[cast(uint)fg].addFace(cast(uint)v1, cast(uint)v2, cast(uint)v3);
    }
    return 1.0;
}

export double dmModelBuildBVH(double model)
{
    Model m = model.toObject!(Model);
    if (m)
    {
        m.buildBVH();
    }
    return 1.0;
}

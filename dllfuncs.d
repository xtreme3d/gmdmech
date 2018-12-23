module dllfuncs;

import core.runtime;
import core.memory;
import dlib.core.memory;
import dlib.core.ownership;
import dlib.container.bst;
import dlib.math.vector;
import dlib.math.matrix;
import dlib.math.transformation;
import dmech.world;
import dmech.rigidbody;
import dmech.geometry;
import dmech.shape;
import dmech.constraint;
import dmech.raycast;
import dmech.contact;
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

class CollisionReporter: Owner, CollisionDispatcher
{
    bool collided = false;
    
    this(Owner o)
    {
        super(o);
    }
    
    void onNewContact(RigidBody rb, Contact c)
    {
        collided = true;
    }
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
    PhysicsWorld world = New!PhysicsWorld(null, cast(uint)maxCollisions);
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

export double dmWorldAddModel(double w, double m)
{
    PhysicsWorld world = w.toObject!(PhysicsWorld);
    if (m != 0.0)
    {
        Model model = m.toObject!(Model);
        if (world && model)
        {
            if (model.bvh)
            {
                world.bvh.append(model.bvh.root);
                return world.bvh.length-1;
            }
            else
                return -1.0;
        }
        else
            return -1.0;
    }
    else
    {
        return -1.0;
    }
}

export double dmWorldRemoveModel(double w, double mi)
{
    PhysicsWorld world = w.toObject!(PhysicsWorld);
    int i = cast(int)mi;
    if (i >= 0)
    {
        if (i < world.bvh.length)
        {
            world.bvh.removeKey(cast(size_t)i);
            return 1.0;
        }
        else
        {
            return 0.0;
        }
    }
    else
        return 0.0;
}

export double dmWorldGetProxyTriShape(double w)
{
    PhysicsWorld world = w.toObject!(PhysicsWorld);
    if (world)
    {
        return world.proxyTriShape.gmptr;
    }
    else
        return 0.0;
}

export double dmWorldClearCollision(double w, double rb1, double rb2)
{
    PhysicsWorld world = w.toObject!(PhysicsWorld);
    if (world)
    {
        RigidBody body1 = rb1.toObject!(RigidBody);
        RigidBody body2 = rb2.toObject!(RigidBody);
        if (rb1 && rb2)
        {
            world.clearCollision(body1, body2);
            return 1.0;
        }
        else
            return 0.0;
    }
    else
        return 0.0;
}

// Geometry

export double dmWorldCreateGeomSphere(double w, double r)
{
    PhysicsWorld world = w.toObject!(PhysicsWorld);
    GeomSphere geom = New!(GeomSphere)(world, r);
    return geom.gmptr;
}

export double dmWorldCreateGeomBox(double w, double hsx, double hsy, double hsz)
{
    PhysicsWorld world = w.toObject!(PhysicsWorld);
    GeomBox geom = New!(GeomBox)(world, Vector3f(hsx, hsy, hsz));
    return geom.gmptr;
}

export double dmWorldCreateGeomCylinder(double w, double h, double r)
{
    PhysicsWorld world = w.toObject!(PhysicsWorld);
    GeomCylinder geom = New!(GeomCylinder)(world, h, r);
    return geom.gmptr;
}

export double dmWorldCreateGeomCone(double w, double h, double r)
{
    PhysicsWorld world = w.toObject!(PhysicsWorld);
    GeomCone geom = New!(GeomCone)(world, h, r);
    return geom.gmptr;
}

export double dmWorldCreateGeomEllipsoid(double w, double rx, double ry, double rz)
{
    PhysicsWorld world = w.toObject!(PhysicsWorld);
    GeomEllipsoid geom = New!(GeomEllipsoid)(world, Vector3f(rx, ry, rz));
    return geom.gmptr;
}

// Collision Shape

export double dmCollisionShapeIsColliding(double s1, double s2)
{
    ShapeComponent sc1 = s1.toObject!(ShapeComponent);
    ShapeComponent sc2 = s2.toObject!(ShapeComponent);
    if (sc1 && sc2)
    {
        auto c1 = sc1.world.manifolds.get(sc1.id, sc2.id);
        auto c2 = sc1.world.manifolds.get(sc2.id, sc1.id);
        
        if (c1 || c2)
            return 1.0;
        else
            return 0.0;
    }
    else
        return 0.0;
}

export double dmCollisionShapeClearCollision(double colshp)
{
    ShapeComponent sc = colshp.toObject!(ShapeComponent);      
    if (sc)
    {
        sc.isColliding = false;
    }
    return 1.0;
}

//TODO: get shape transformation

// Body

export double dmBodyUseGravity(double b, double m)
{
    RigidBody rb = b.toObject!(RigidBody);      
    if (rb)
    {
        rb.useGravity = cast(bool)(cast(int)m);
    }
    return 1.0;
}

export double dmBodyApplyForce(double b, double x, double y, double z)
{
    RigidBody rb = b.toObject!(RigidBody);      
    if (rb)
    {
        rb.applyForce(Vector3f(x, y, z));
    }
    return 1.0;
}

export double dmBodySetPosition(double b, double x, double y, double z)
{
    RigidBody rb = b.toObject!(RigidBody);      
    if (rb)
    {
        rb.position = Vector3f(x, y, z);
    }
    return 1.0;
}

export double dmBodyAimToPosition(double b, double x, double y, double z, double dt, double bias)
{
    RigidBody rb = b.toObject!(RigidBody);      
    if (rb)
    {
        Vector3f posDelta = Vector3f(x, y, z) - rb.position;
        Vector3f targetVelocity = posDelta / dt;
        rb.linearVelocity = targetVelocity * bias;
    }
    return 1.0;
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

export double dmBodySetVelocity(double b, double x, double y, double z)
{
    RigidBody rb = b.toObject!(RigidBody);      
    if (rb)
    {
        rb.linearVelocity = Vector3f(x, y, z);
    }
    return 1.0;
}

export double dmBodyGetVelocity(double b, double index)
{
    RigidBody rb = b.toObject!(RigidBody);      
    if (rb)
    {
        return rb.linearVelocity.arrayof[cast(uint)index];
    }
    else
        return 0.0;
}

export double dmBodyGetSpeed(double b)
{
    RigidBody rb = b.toObject!(RigidBody);      
    if (rb)
    {
        return rb.linearVelocity.length;
    }
    else
        return 0.0;
}

export double dmBodySetCollisionLayer(double b, double layer)
{
    RigidBody rb = b.toObject!(RigidBody);      
    if (rb)
    {
        rb.collisionLayer = cast(int)layer;
        return 1.0;
    }
    else
        return 0.0;
}

export double dmBodySetRaycastable(double b, double mode)
{
    RigidBody rb = b.toObject!(RigidBody);      
    if (rb)
    {
        rb.raycastable = cast(bool)cast(int)mode;
        return 1.0;
    }
    else
        return 0.0;
}

// Collision

export double dmCreateCollisionReporter(double b)
{
    RigidBody rb = b.toObject!(RigidBody);
    if (rb)
    {
        CollisionReporter r = New!CollisionReporter(rb);
        rb.collisionDispatchers.append(r);
        return r.gmptr;
    }
    else
    {
        return 0.0;
    }
}

export double dmCollisionReporterGetState(double r)
{
    CollisionReporter rp = r.toObject!(CollisionReporter);
    if (rp)
    {
        return rp.collided;
    }
    else
    {
        return 0.0;
    }
}

export double dmCollisionReporterSetState(double r, double s)
{
    CollisionReporter rp = r.toObject!(CollisionReporter);
    if (rp)
    {
        rp.collided = cast(bool)(cast(int)s);
        return 1.0;
    }
    else
    {
        return 0.0;
    }
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

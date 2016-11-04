module model;

import std.math;

import dlib.core.memory;
import dlib.math.vector;
import dlib.math.matrix;
import dlib.math.affine;
import dlib.math.utils;
import dlib.geometry.triangle;
import dlib.container.array;

import dmech.bvh;

class Facegroup
{
    DynamicArray!(uint[3]) indices;
    
    size_t addFace(uint v1, uint v2, uint v3)
    {
        uint[3] i;
        i[0] = v1;
        i[1] = v2;
        i[2] = v3;
        indices.append(i);
        return indices.length - 1;
    }
    
    ~this()
    {
        indices.free();
    }
}

class Mesh
{    
    DynamicArray!Vector3f vertices;
    DynamicArray!Vector3f normals;
    DynamicArray!Facegroup facegroups;
    
    ~this()
    {
        vertices.free();
        normals.free();
        foreach(i, f; facegroups)
        {
            Delete(f);
        }
        facegroups.free();
    }
    
    size_t addVertex(Vector3f v)
    {
        vertices.append(v);
        return vertices.length - 1;
    }
    
    size_t addNormal(Vector3f n)
    {
        normals.append(n);
        return normals.length - 1;
    }
    
    size_t addFacegroup()
    {
        Facegroup fg = New!Facegroup();
        facegroups.append(fg);
        return facegroups.length - 1;
    }
}

class Model
{
    DynamicArray!Mesh meshes;
    BVHTree!Triangle bvh;
    
    ~this()
    {
        foreach(i, m; meshes)
        {
            Delete(m);
        }
        meshes.free();
        
        if (bvh)
            bvh.free();
    }
    
    size_t addMesh()
    {
        Mesh m = New!Mesh();
        meshes.append(m);
        return meshes.length - 1;
    }

    void buildBVH()
    {
        DynamicArray!Triangle tris;
        
        foreach(mi, m; meshes)
        foreach(fgi, fg; m.facegroups)
        foreach(ti, tri; fg.indices)
        {
            Triangle tri2;
            tri2.v[0] = m.vertices[tri[0]];// * mat;
            tri2.v[1] = m.vertices[tri[1]];// * mat;
            tri2.v[2] = m.vertices[tri[2]];// * mat;
            
            tri2.normal = Vector3f(0, 0, 0);
            if (m.normals.length)
            {
                tri2.normal += m.normals[tri[0]];
                tri2.normal += m.normals[tri[1]];
                tri2.normal += m.normals[tri[2]];
                tri2.normal = (tri2.normal / 3.0f);
                //tri2.normal = e.rotation.rotate(tri2.normal);
            }
            
            tri2.barycenter = (tri2.v[0] + tri2.v[1] + tri2.v[2]) / 3.0f;
            tris.append(tri2);
        }
        
        bvh = New!(BVHTree!Triangle)(tris, 10, 20);
        tris.free();
    }
}

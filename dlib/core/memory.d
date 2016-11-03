﻿/*
Copyright (c) 2015 Timur Gafarov

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

module dlib.core.memory;

import std.stdio;
import std.conv;
import std.traits;
import core.stdc.stdlib;
import core.exception: onOutOfMemoryError;

/*
 * Tools for manual memory management
 */

//version = MemoryDebug;

private __gshared static size_t _allocatedMemory = 0;

version(MemoryDebug)
{
    import std.datetime;
    import std.algorithm;
    
    struct AllocationRecord
    {
        string type;
        size_t size;
        ulong id;
        bool deleted;
    }
    
    AllocationRecord[ulong] records;
    ulong counter = 0;
    
    void addRecord(void* p, string type, size_t size)
    {
        records[cast(ulong)p] = AllocationRecord(type, size, counter, false);
        counter++;
        //writefln("Allocated %s (%s bytes)", type, size);
    }
    
    void markDeleted(void* p)
    {
        ulong k = cast(ulong)p - psize;
        //string type = records[k].type;
        //size_t size = records[k].size;
        records[k].deleted = true;
        //writefln("Dellocated %s (%s bytes)", type, size);
    }
    
    void printMemoryLog()
    {
        writeln("----------------------------------------------------");
        writeln("               Memory allocation log                ");
        writeln("----------------------------------------------------");
        auto keys = records.keys;
        sort!((a, b) => records[a].id < records[b].id)(keys);
        foreach(k; keys)
        {
            AllocationRecord r = records[k];
            if (r.deleted)
                writefln("         %s - %s byte(s) at %X", r.type, r.size, k);
            else
                writefln("REMAINS: %s - %s byte(s) at %X", r.type, r.size, k);
        }
        writeln("----------------------------------------------------");
        writefln("Total amount of allocated memory: %s", _allocatedMemory);
        writeln("----------------------------------------------------");
    }
}
else
{
    void printMemoryLog() {}
}

size_t allocatedMemory()
{
    return _allocatedMemory;
}

interface Freeable
{
    void free();
}

enum psize = 8;

T allocate(T, A...) (A args) if (is(T == class))
{
    enum size = __traits(classInstanceSize, T);
    void* p = malloc(size+psize);
    if (!p)
        onOutOfMemoryError();
    auto memory = p[psize..psize+size];
    *cast(size_t*)p = size;
    _allocatedMemory += size;
    version(MemoryDebug)
    {
        addRecord(p, T.stringof, size);
    }
    auto res = emplace!(T, A)(memory, args);
    return res;
}

T* allocate(T, A...) (A args) if (is(T == struct))
{
    enum size = T.sizeof;
    void* p = malloc(size+psize);
    if (!p)
        onOutOfMemoryError();
    auto memory = p[psize..psize+size];
    *cast(size_t*)p = size;
    _allocatedMemory += size;
    version(MemoryDebug)
    {
        addRecord(p, T.stringof, size);
    }
    return emplace!(T, A)(memory, args);
}

T allocate(T) (size_t length) if (isArray!T)
{
    alias AT = ForeachType!T;
    size_t size = length * AT.sizeof;
    auto mem = malloc(size+psize);
    if (!mem)
        onOutOfMemoryError();
    T arr = cast(T)mem[psize..psize+size];
    foreach(ref v; arr)
        v = v.init;
    *cast(size_t*)mem = size;
    _allocatedMemory += size;
    version(MemoryDebug)
    {
        addRecord(mem, T.stringof, size);
    }
    return arr;
}

void deallocate(T)(ref T obj) if (isArray!T)
{
    void* p = cast(void*)obj.ptr;
    size_t size = *cast(size_t*)(p - psize);
    free(p - psize);
    _allocatedMemory -= size;
    version(MemoryDebug)
    {
        markDeleted(p);
    }
    obj.length = 0;
}

void deallocate(T)(T obj) if (is(T == class) || is(T == interface))
{
    Object o = cast(Object)obj;
    void* p = cast(void*)o;
    size_t size = *cast(size_t*)(p - psize);
    destroy(obj);
    free(p - psize);
    _allocatedMemory -= size;
    version(MemoryDebug)
    {
        markDeleted(p);
    }
}

void deallocate(T)(T* obj)
{
    void* p = cast(void*)obj;
    size_t size = *cast(size_t*)(p - psize);
    destroy(obj);
    free(p - psize);
    _allocatedMemory -= size;
    version(MemoryDebug)
    {
        markDeleted(p);
    }
}

alias allocate New;
alias deallocate Delete;

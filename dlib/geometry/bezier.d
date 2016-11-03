/*
Copyright (c) 2013 Timur Gafarov 

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

module dlib.geometry.bezier;

private
{
    import dlib.math.vector;
}

T bezier(T) (T A, T B, T C, T D, T t)
{
    T s = cast(T)1.0 - t;
    T AB = A * s + B * t;
    T BC = B * s + C * t;
    T CD = C * s + D * t;
    T ABC = AB * s + CD * t;
    T BCD = BC * s + CD * t;
    return ABC * s + BCD * t;
}

Vector!(T,3) bezierCurveFunc3D(T)(
    Vector!(T,3) a,
    Vector!(T,3) b,
    Vector!(T,3) c,
    Vector!(T,3) d,
    T t)
{
    return Vector!(T,3)
    (
        bezier(a.x, b.x, c.x, d.x, t),
        bezier(a.y, b.y, c.y, d.y, t),
        bezier(a.z, b.z, c.z, d.z, t)
    );
}

Vector!(T,2) bezierCurveFunc2D(T)(
    Vector!(T,2) a,
    Vector!(T,2) b,
    Vector!(T,2) c,
    Vector!(T,2) d,
    T t)
{
    return Vector!(T,2)
    (
        bezier(a.x, b.x, c.x, d.x, t),
        bezier(a.y, b.y, c.y, d.y, t)
    );
}

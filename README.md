gmdmech
=======
This is a work-in-progress [dmech](https://github.com/gecko0307/dmech) physics engine wrapper for Game Maker 8, designed specifically to work with [Xtreme3D 3.x](https://github.com/xtreme3d/xtreme3d). Xtreme3D already includes a physics engine, ODE, but it has some pitfalls and limitations (and actually is not up to date with latest ODE), so it would be nice to have an alternative. dmech is, in turn, a simple, but fully-functional game-oriented physics library, which can be used both for dynamics and kinematics simultaneously.

Currently gmdmech provides the following functionality:
* Creation of physics worlds
* Static and dynamic bodies
* Geometric shapes for bodies: sphere, box, cylinder, cone, ellipsoid
* Arbitrary static meshes
* Built-in character controller that can move, jump and interact with other bodies - very useful for games
* A number of helper functions for integration with Xtreme3D (syncing bodies with objects, creating meshes from Freeforms, etc).

There is a simple Xtreme3D-based example (dmech-demo.gmk) that demonstrates how to create bodies and a character that is controlled by the player.

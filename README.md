gmdmech
=======
This is a work-in-progress [dmech](https://github.com/gecko0307/dmech) physics engine wrapper for Game Maker 8, designed specifically to work with [Xtreme3D 3.x](https://github.com/xtreme3d/xtreme3d). Xtreme3D already includes a physics engine, ODE, but it has some pitfalls and limitations (and actually is not up to date with latest ODE), so it would be nice to have an alternative. dmech is, in turn, a simple, but fully-functional game-oriented physics library, which can be used both for dynamics and kinematics simultaneously.

Currently gmdmech wraps only basic functions of dmech, such as creation of physics worlds, adding static and dynamic bodies and attaching geometric shapes. Look dmech-demo.gmk for details.

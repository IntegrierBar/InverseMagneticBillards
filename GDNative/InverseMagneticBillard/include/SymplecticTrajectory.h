/*
This class handles the symplectic iteration of the polygon. NO MAGNETIC FIELD
We extend "Trajectory" and only change the "iterate" and do not use the intersection functions
*/

#pragma once

#include <vector>
#include <Color.hpp>
#include <Vectors.h>
#include <Trajectory.h>
#include <PoolArrays.hpp>
#include <Array.hpp>

namespace godot {
    struct SymplecticTrajectory : public Trajectory {
    public:
        Vector2 iterate();                          // iterates backwards
        PoolVector2Array iterate_batch(int batch);

    private:
    };


}
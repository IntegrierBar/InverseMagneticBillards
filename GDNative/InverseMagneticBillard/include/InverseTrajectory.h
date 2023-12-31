/*
This class handles the inverse iteration of the inverse magnetic billard
This means that it iterates backwards
We extend "Trajectory" and only change the "iterate" and the intersection functions
*/

#pragma once

#include <vector>
#include <Color.hpp>
#include <Vectors.h>
#include <Trajectory.h>
#include <PoolArrays.hpp>
#include <Array.hpp>

namespace godot {
    struct InverseTrajectory : public Trajectory {
    public:
        std::optional<Vector2> iterate();                          // iterates backwards with inverse magnetic billard
        PoolVector2Array iterate_batch(int batch);

        std::optional<Vector2> iterate_symplectic();
        PoolVector2Array iterate_symplectic_batch(int batch);

        std::optional<Vector2> iterate_regular();
        PoolVector2Array iterate_regular_batch(int batch);

    protected:
        /* Functions used to calculate the iterations of the trajectory */

        // intersects the line defined by "start" and "dir" with the polygon. 
        // Returns the closest intersection in NEGATIVE direction together with the index of the edge of the polygon
        // COULD CONSIDER USING OPTIONAL AS WELL HERE; BUT NOT REALY NECCESSARY AS THIS CLASS IS ONLY USED WHEN HOVERING OVER THE FLOWMAP
        std::pair<vec2_d, int> intersect_polygon_line(vec2_d start, vec2_d dir);

        // "center" is the center of the circle, "start" is on the circle and "dir" the tangent at "start"
        // it then calculates all intersections of the circle with the polygon
        // returns the first intersection CLOCKWISE starting from "start" and the index of the edge of the polygon
        std::pair<vec2_d, int> intersect_polygon_circle(vec2_d start, vec2_d dir, vec2_d center);
    };


}
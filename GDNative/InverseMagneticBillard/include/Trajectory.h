#pragma once

#include <Vectors.h>
#include <Vector2.hpp>
#include <vector>
#include <Color.hpp>
#include <Array.hpp>
#include <PoolArrays.hpp>
// Trajectory class

namespace godot {
	struct Trajectory {
	public:
        double eps = 1e-8;  // TODO maybe make global eps or something?
        double radius = 1;
        int maxCount = 1000;
        int count = 0;  // how many interations are done

        Color trajectoryColor = Color(0, 1, 0);

        std::vector<vec2_d> polygon;    // keep one structure for calculations
        std::vector<double> polygonLength;  // polygonLength[i] is the length from start to edge i, not including edge i (will always have size = polygon.size)

        vec2_d currentDirection = vec2_d(1, 0);
        vec2_d currentPosition = vec2_d(0, 0);
        int currentIndexOnPolygon = 0; // index to track in which edge on the polygon we are
        std::vector<vec2_d> trajectory;
        std::vector<vec2_d> phaseSpaceTrajectory;   // the trajectory points in the phase space [0,1] x [0,1] CONVENTION: first variable is coord on polygon, second is angle
        // use one long polyline for drawing
        PoolVector2Array trajectoryToDraw;


		Trajectory();
		~Trajectory();

        void set_initial_values(vec2_d start, vec2_d dir);
        void set_initial_values(vec2_d pos); // use phasespace coords to set inital values
        void reset_trajectory();

        void iterate();
        void iterate_batch(int batch);

	private:
        std::pair<vec2_d, int> intersect_polygon_line(vec2_d start, vec2_d dir);
        std::pair<vec2_d, int> intersect_polygon_circle(vec2_d start, vec2_d dir, vec2_d center);
	};

	
}
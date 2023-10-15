/*
This class handles the iteration of the inverse magnetic billard
*/

#pragma once

#include <Vectors.h>
#include <Vector2.hpp>
#include <vector>
#include <Color.hpp>
#include <Array.hpp>
#include <PoolArrays.hpp>

namespace godot {
	struct Trajectory {
	public:
        double eps = 1e-8;      // used to determine if two points are the same
        double radius = 1;      // radius of the system. Equal to ~ 1/magnetic strength
        int maxCount = 100;     // how many iteration should be drawn. Will still compute more iterations after this but wont add to "trajectoryToDraw"
        int count = 0;          // how many interations have been calculated

        Color trajectoryColor = Color(0, 1, 0);     // color with which the trajectory is drawn in normal space and phase space

        std::vector<vec2_d> polygon;                // defines the "table" for the IMB. IMPORTANT: polygon[0] = polygon[-1] is neccessary for algorithms
        std::vector<double> polygonLength;          // polygonLength[i] is the length from start to edge i, not including edge i, e.g. polylength[0] = 0 and polylength[-1] = circumference of the polygon (will always have size = polygon.size)

        vec2_d currentDirection = vec2_d(1, 0);     // 2d direction used for the next iteration (normalized)
        vec2_d currentPosition = vec2_d(0, 0);      // 2d position used for the next iteration
        int currentIndexOnPolygon = 0;              // index to track in which edge on the polygon current position is (this is used in intersect_polygon_line, to make sure we don't get currentPosition as the intersection)
        std::vector<vec2_d> trajectory;             // vector of all currentPositions throughout all iterations. After each iteration, this is appended by currentPosition
        std::vector<vec2_d> phaseSpaceTrajectory;   // the trajectory in phase space coordinates [0,1] x [0,1]. CONVENTION: first variable is coord on polygon, second is angle

        // use one long polyline for drawing in normal space
        // Important: Godot drawing works with negative y axis. Therefore use .to_draw() conversion
        PoolVector2Array trajectoryToDraw;          // this is used to draw the trajectory in normal space


		Trajectory();
		~Trajectory();

        void set_initial_values(vec2_d start, vec2_d dir);  // also clears "trajectory", "phaseSpaceTrajectory" and "trajectoryToDraw"
        void set_initial_values(vec2_d pos);                // use phasespace coords to set inital values
        void reset_trajectory();                            // reset to inital state (direction and position). Uses phasespaceTrajectory[0] to get the coordinates.

        void set_polygon(std::vector<vec2_d> p, std::vector<double> l); // set the polygon. Keeps the inital phasespace coordinates

        Vector2 iterate();                                  // one iteration of the system. Returns the phase space coordinates of the new point
        PoolVector2Array iterate_batch(int batch);          // "batch" iterations of the system. Returns Array of all phase space coordinates of the iterations

        // symplectic iteration
        Vector2 iterate_symplectic();                                  // one iteration of the system. Returns the phase space coordinates of the new point
        PoolVector2Array iterate_symplectic_batch(int batch);          // "batch" iterations of the system. Returns Array of all phase space coordinates of the iterations

	protected:
        /* Functions used to calculate the iterations of the trajectory */

        // intersects the line defined by "start" and "dir" with the polygon. 
        // Returns the closest intersection in positive direction together with the index of the edge of the polygon
        std::pair<vec2_d, int> intersect_polygon_line(vec2_d start, vec2_d dir);    

        // "center" is the center of the circle, "start" is on the circle and "dir" the tangent at "start"
        // it then calculates all intersections of the circle with the polygon
        // returns the first intersection counterclockwise starting from "start" and the index of the edge of the polygon
        std::pair<vec2_d, int> intersect_polygon_circle(vec2_d start, vec2_d dir, vec2_d center);
	};

	
}
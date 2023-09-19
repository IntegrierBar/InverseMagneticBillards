#ifndef GDNATIVEEXPLORATION_IMB_H
#define GDNATIVEEXPLORATION_IMB_H

#include <Godot.hpp>
#include <KinematicBody2D.hpp>
#include <Input.hpp>
#include <Vectors.h>
#include <Vector2.hpp>
#include <vector>
#include <array>
#include <algorithm>
#include <utility>
#include <cmath>
#include <string>
#include <Array.hpp>
#include <Color.hpp>
#include <Trajectory.h>
#include <OS.hpp>
#include <InverseTrajectory.h>

namespace godot {
    class InverseMagneticBillard : public Node2D {
    private:

        // We need to register some information to Godot
        GODOT_CLASS(InverseMagneticBillard, Node2D)
    public:
        static void _register_methods();
        void _init();
        void _process();    // currently not used
        void _draw();
        
        InverseMagneticBillard() {}
        ~InverseMagneticBillard() {}
        
        // Member fields
        double radius = 1;

        int maxCount = 100;

        bool polygonClosed = false;
        std::vector<vec2_d> polygon;    // keep one structure for calculations
        std::vector<double> polygonLength;  // polygonLength[i] is the length from start to vertex i, not including edge i (will always have size = polygon.size )

        std::vector<Trajectory> trajectories;
        std::vector<InverseTrajectory> inverseTrajectories;
        
        

        // Member functions
        void set_radius(double r);
        void clear_polygon();
        void add_polygon_vertex(Vector2 vertex);
        void close_polygon();
        //void make_regular_ngon(int n, double radius=1);

        void add_trajectory(Vector2 start, Vector2 dir, Color color);
        void add_inverse_trajectory(Vector2 start, Vector2 dir, Color color);
        void add_trajectory_phasespace(Vector2 pos, Color color);
        void add_inverse_trajectory_phasespace(Vector2 pos, Color color);
        void remove_trajectory(int index);
        //void remove_inverse_trajectory(int index);
        void clear_trajectories();  // remove all trajectories
        
        void reset_trajectories();
        void set_initial_values(int index, Vector2 start, Vector2 dir);
        void set_color(int index, Color c); // set color of trajectory 'index'
        void set_max_count(int index, int newMaxCount);

        PoolColorArray get_trajectory_colors(); // use this to access all colors of the trajectories

        Array get_trajectories();
        Array iterate_batch(int batch); // returns array of PoolVector2Arrays of the phasespace coords of all trajectories
        Array iterate_inverse_batch(int batch);
    };
}

#endif //GDNATIVEEXPLORATION_IMB_H
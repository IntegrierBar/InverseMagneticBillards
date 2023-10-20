/*
Manager class that is exposed to Godot
Manages trajectories and inverse trajectories and the drawing
*/

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
#include <optional>
//#include <SymplecticTrajectory.h>

namespace godot {
    class InverseMagneticBillard : public Node2D {
    private:

        // We need to register some information to Godot
        GODOT_CLASS(InverseMagneticBillard, Node2D)
    public:
        static void _register_methods();
        void _init();       // currently not used
        void _ready();      // used to deacitvate _process function
        void _process();    // currently not used
        void _draw();
        
        InverseMagneticBillard() {}
        ~InverseMagneticBillard() {}
        
        // Member fields
        int billardType = 0;                // decides the billard type for the iteration (0 = inverse magnetic, 1 = symplectic). Uses int instead of bool to allow for further additions.

        double radius = 1;                  // default radius of the system. Equal to ~ 1/magnetic strength
        int maxCount = 100;                 // default "maxCount" for the trajectories

        bool polygonClosed = false;         // variable to track whether the polygon is closed, i.e. polygon[0] == polygon[-1] 
        std::vector<vec2_d> polygon;        // polygon that defines the table
        std::vector<double> polygonLength;  // polygonLength[i] is the length from start to vertex i, not including edge i (will always have size = polygon.size )

        // vectors to store the trajectories and inverse trajectories
        std::vector<Trajectory> trajectories;
        std::vector<InverseTrajectory> inverseTrajectories;

        // variables to automatically fill phasespace
        int gridSize = 64;               // grid the phasespace into resolution^2 boxes (divide each axis into resolution amount parts)
        std::vector<std::vector<bool>> grid;// grid of the phasespace. Each cells remembers if there is no point inside (true if empty)
        int defaultBatch = 1000;            // batch size done in every iteration
        
        

        // Member functions
        void set_billard_type(int type);                    // used by other godot nodes to set the type. Resets all trajectories

        void set_radius(double r);
        void clear_polygon();
        void add_polygon_vertex(Vector2 vertex);
        void close_polygon();                               // closes the polygon by appending polygon[0] at the end
        void set_polygon_vertex(int index, Vector2 vertex); // set polygon[index] = vertex

        void add_trajectory(Vector2 start, Vector2 dir, Color color);           // add trajectory with initial values start and direction
        void add_trajectory_phasespace(Vector2 pos, Color color);               // add trajectory with initial values from phase space coordinates
        void remove_trajectory(int index);                                      // remove trajectory at index "index"
        //void remove_inverse_trajectory(int index);

        void add_inverse_trajectory(Vector2 start, Vector2 dir, Color color);   // add inverse trajectory with initial values start and direction
        void add_inverse_trajectory_phasespace(Vector2 pos, Color color);       // add inverse trajectory with initial values from phase space coordinates
        //void remove_inverse_trajectory(int index);

        //void add_symplectic_trajectory(Vector2 start, Vector2 dir, Color color);   // add symplectic trajectory with initial values start and direction
        //void add_symplectic_trajectory_phasespace(Vector2 pos, Color color);       // add symplectic trajectory with initial values from phase space coordinates
        ////void remove_inverse_trajectory(int index);

        void clear_trajectories();                                              // remove all trajectories and inverse trajectories
        
        void reset_trajectories();                                              // reset all trajectories and inverse trajectories and symplectic trajectories
        void set_initial_values(int index, Vector2 start, Vector2 dir);         // set the initial values of trajectory with index "index"
        void set_color(int index, Color c);                                     // set color of trajectory 'index'
        void set_max_count(int index, int newMaxCount);                         // set maxCount of trajectory 'index'

        PoolColorArray get_trajectory_colors();                                 // returns Godot array of all colors of the trajectories

        Array get_trajectories();                                               // returns array of "currentPosition"s of all trajectories 
        Array iterate_batch(int batch);                                         // iterates all trajectories and returns a 2d array with all phasespace coordinates from the iteration
        PoolVector2Array iterate_trajectory(int index, int batch);              // iterates the "index"-th trajectory
        Array iterate_inverse_batch(int batch);
        //Array iterate_symplectic_batch(int batch);

        // helper functions for automatic filling of phasespace
        void set_grid_size(int gs);
        Vector2 hole_in_phasespace();                                           // finds a large hole in the current phasespace and returns a point inside it. Used to automatically fill the phasespace
        void fill_grid_with_points(PoolVector2Array points);
    };
}

#endif //GDNATIVEEXPLORATION_IMB_H
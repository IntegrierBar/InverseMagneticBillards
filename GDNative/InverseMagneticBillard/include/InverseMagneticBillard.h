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

namespace godot {
    class InverseMagneticBillard : public Node2D {
    private:

        // We need to register some information to Godot
        GODOT_CLASS(InverseMagneticBillard, Node2D)
    public:
        static void _register_methods();
        void _init();
        void _process();
        void _draw();
        
        InverseMagneticBillard() {}
        ~InverseMagneticBillard() {}
        
        double eps = 1e-8;
        // Member fields
        double radius = 1;

        int maxCount = 1000;
        //int batch = 100;
        int count = 0;  // how many interations are done
        bool polygonClosed = false;
        std::vector<vec2_d> polygon;    // keep one structure for calculations
        std::vector<double> polygonLength;  // polygonLength[i] is the length from start to edge i, including edge i (will always have size = polygon.size - 1)
        Color trajectoryColor = Color(0, 1, 0);
        //PoolVector2Array polygonToDraw; // and one for drawing. Remeber to always update both together POLYGON IS DRAWN IN MANAGER NODE
        //Color polygonColor = Color(1, 1, 1);
        vec2_d currentDirection = vec2_d(1, 0);
        int currentIndexOnPolygon = 0; // index to trackj in which edge on the polygon we are
        vec2_d currentPosition = vec2_d(0, 0);
        std::vector<vec2_d> trajectory;
        //std::vector<Vector2> trajectoryDraw; For debugging
        std::vector<std::array<Vector2, 2>> trajectoryLines;
        std::vector<std::tuple<vec2_d, double, double>> trajectoryCircles; // TODO maybe use better structure here?
        std::vector<vec2_d> phaseSpaceTrajectory;   // the trajectory points in the phase space [0,1] x [0,1] CONVENTION: first variable is coord on polygon, second is angle
        
        
        

        // Member functions
        void set_radius(double r);
        void clear_polygon();
        void add_polygon_vertex(Vector2 vertex);
        void close_polygon();
        //void set_direction(Vector2 direction);
        void reset_trajectory();
        void set_initial_values(Vector2 start, Vector2 dir);
        //void set_start(Vector2 start);
        Vector2 iterate();     // make iterate return the phase space points as Vector2
        PoolVector2Array iterate_batch(int batch);
        std::pair<vec2_d, int> intersect_polygon_line(vec2_d start, vec2_d dir);
        std::pair<vec2_d, int> intersect_polygon_circle(vec2_d start, vec2_d dir, vec2_d center);
    };
}

#endif //GDNATIVEEXPLORATION_IMB_H
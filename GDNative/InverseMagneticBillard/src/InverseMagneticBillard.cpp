#include "InverseMagneticBillard.h"
#include <iostream>



namespace godot {
  

    void InverseMagneticBillard::_init()
    {
    }

    void InverseMagneticBillard::_register_methods()
    {
        register_method((char*)"_process", &InverseMagneticBillard::_process);
        register_method((char*)"_draw", &InverseMagneticBillard::_draw);
        register_method((char*)"clear_polygon", &InverseMagneticBillard::clear_polygon);
        register_method((char*)"add_polygon_vertex", &InverseMagneticBillard::add_polygon_vertex);
        register_method((char*)"close_polygon", &InverseMagneticBillard::close_polygon);
        register_method((char*)"set_radius", &InverseMagneticBillard::set_radius);
        register_method((char*)"set_initial_values", &InverseMagneticBillard::set_initial_values);
        register_method((char*)"add_trajectory", &InverseMagneticBillard::add_trajectory);
        register_method((char*)"remove_trajectory", &InverseMagneticBillard::remove_trajectory);
        register_method((char*)"reset_trajectories", &InverseMagneticBillard::reset_trajectories);
        register_method((char*)"iterate_batch", &InverseMagneticBillard::iterate_batch);
        register_property<InverseMagneticBillard, double>((char*)"radius", &InverseMagneticBillard::radius, 1);
        register_property((char*)"maxCount", &InverseMagneticBillard::maxCount, 1000);
        register_property((char*)"polygonClosed", &InverseMagneticBillard::polygonClosed, false);
    }

    void InverseMagneticBillard::_process()
    {
        // TODO could do stuff here
    }

    void InverseMagneticBillard::_draw()
    {
        // TODO consider using antialiasing and width
        for (auto& t : trajectories) {
            if (t.trajectoryToDraw.size() > 1)
            {
                draw_polyline(t.trajectoryToDraw, t.trajectoryColor);
            }
            
        }


        /* draw the polygon TODO maybe add width and antialiasing
        // TODO consider not drawing the polygon here, but with gd script in the manager node!
        if (polygonToDraw.size() > 1) {
            draw_polyline(polygonToDraw, polygonColor);
        }
        

        // draw trajectory
        //for (const auto& line : trajectoryLines) {
        //    draw_line(line[0], line[1], trajectoryColor);
        //}
        //for (const auto& circle : trajectoryCircles) {
        //    draw_arc(std::get<0>(circle).to_godot(), radius, std::get<1>(circle), std::get<2>(circle), 20, trajectoryColor);
        //}

        // DEGUB
        //for (const auto& point : trajectoryDraw) {
            //draw_circle(point, 20, Color(1, 0, 0));
        //}
        */
    }

    void InverseMagneticBillard::clear_polygon()
    {
        polygonClosed = false;
        polygon = {};
        polygonLength = {};
        reset_trajectories();
        update();
    }

    // CURRENTLY BETTER NOT USED
    void InverseMagneticBillard::add_polygon_vertex(Vector2 vertex)
    {
        //Godot::print("add vertex to polygon");
        //Godot::print(vertex);
        if (polygonClosed) {    // if the polygon es closed, remember, that last element of vector is first element.
            //polygonClosed = false;
            //polygon.pop_back();
            ////polygonToDraw.remove(polygonToDraw.size() - 1);
            //polygon.push_back(vec2_d(vertex));
            ////polygonToDraw.push_back(vertex);
            //close_polygon();

            // DONT DO ANYTHING IF POLYGON IS CLOSED
            // THIS IS IMPORTANT FOR LENGTH CALCULATIONS. MAYBE CHANGE LATER
        }
        else {
            if (polygon.size() > 0)
            {
                if (polygonLength.size() < 1) { // TODO should be unneccessary now
                    polygonLength.push_back(length(polygon.back() - vec2_d(vertex)));
                }
                else {
                    polygonLength.push_back(polygonLength.back() + length(polygon.back() - vec2_d(vertex)));

                }
                
            }
            else
            {
                polygonLength.push_back(0); // first entry needs to by a zero
            }
            
            polygon.push_back(vec2_d(vertex));
        }
        //update();
    }

    void InverseMagneticBillard::close_polygon()
    {
        if (polygonClosed || polygon.size() < 3) { return; }    // polygon needs to haev at least 3 edges

        polygonLength.push_back(polygonLength.back() + length(polygon.back() - vec2_d(polygon[0])));
        

        polygon.push_back(polygon[0]);
        polygonClosed = true;

        // only update polygon for the trajectories, once polygon is closed
        for (auto& t : trajectories) {
            t.polygon = polygon;
            t.polygonLength = polygonLength;
        }

        update();
    }

    void InverseMagneticBillard::add_trajectory(Vector2 start, Vector2 dir, Color color)
    {
        Trajectory t = Trajectory();
        t.radius = radius;
        t.maxCount = maxCount;
        t.trajectoryColor = color;

        t.polygon = polygon;
        t.polygonLength = polygonLength;

        t.set_initial_values(vec2_d(start), vec2_d(dir));
        trajectories.push_back(t);
    }

    void InverseMagneticBillard::remove_trajectory(int index)
    {
    }

    

    void InverseMagneticBillard::iterate_batch(int batch)
    {
        for (auto& t : trajectories)
        {
            t.iterate_batch(batch);
        }
        /*PoolVector2Array coordinatesPhasespace = PoolVector2Array();
        if (count + batch > maxCount) { return coordinatesPhasespace; }
        coordinatesPhasespace.resize(batch);
        for (size_t i = 0; i < batch; i++)
        {
            coordinatesPhasespace.set(i, iterate());
        }
        update();
        return coordinatesPhasespace;*/
        update();
    }



    void InverseMagneticBillard::set_initial_values(int index, Vector2 start, Vector2 dir)
    {
        trajectories[index].set_initial_values(start, dir);
        update();
    }



    void InverseMagneticBillard::set_radius(double r)
    {
        radius = r;
        for (auto& t : trajectories)
        {
            t.radius = r;
            t.reset_trajectory();
        }
        update();
    }



    void InverseMagneticBillard::reset_trajectories()
    {
        for (auto& t : trajectories)
        {
            t.reset_trajectory();
        }
        update();
    }

    

}
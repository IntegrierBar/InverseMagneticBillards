#include "InverseMagneticBillard.h"
#include <iostream>



namespace godot {
  

    void InverseMagneticBillard::_init()
    {
    }

    void InverseMagneticBillard::_register_methods()
    {
        //register_method((char*)"_process", &InverseMagneticBillard::_process);
        register_method((char*)"_draw", &InverseMagneticBillard::_draw);
        register_method((char*)"clear_polygon", &InverseMagneticBillard::clear_polygon);
        register_method((char*)"add_polygon_vertex", &InverseMagneticBillard::add_polygon_vertex);
        register_method((char*)"close_polygon", &InverseMagneticBillard::close_polygon);
        register_method((char*)"set_polygon_vertex", &InverseMagneticBillard::set_polygon_vertex);
        register_method((char*)"set_radius", &InverseMagneticBillard::set_radius);
        register_method((char*)"set_initial_values", &InverseMagneticBillard::set_initial_values);
        register_method((char*)"add_trajectory", &InverseMagneticBillard::add_trajectory);
        register_method((char*)"add_trajectory_phasespace", &InverseMagneticBillard::add_trajectory_phasespace);
        register_method((char*)"remove_trajectory", &InverseMagneticBillard::remove_trajectory);
        register_method((char*)"clear_trajectories", &InverseMagneticBillard::clear_trajectories);
        register_method((char*)"get_trajectory_colors", &InverseMagneticBillard::get_trajectory_colors);
        register_method((char*)"get_trajectories", &InverseMagneticBillard::get_trajectories);
        register_method((char*)"set_color", &InverseMagneticBillard::set_color);
        register_method((char*)"set_max_count", &InverseMagneticBillard::set_max_count);
        register_method((char*)"reset_trajectories", &InverseMagneticBillard::reset_trajectories);
        register_method((char*)"iterate_batch", &InverseMagneticBillard::iterate_batch);
        
        // for inverse Trajectories
        register_method((char*)"add_inverse_trajectory", &InverseMagneticBillard::add_inverse_trajectory);
        register_method((char*)"add_inverse_trajectory_phasespace", &InverseMagneticBillard::add_inverse_trajectory_phasespace);
        register_method((char*)"iterate_inverse_batch", &InverseMagneticBillard::iterate_inverse_batch);

        //register_property<InverseMagneticBillard, double>((char*)"radius", &InverseMagneticBillard::radius, 1);
        //register_property((char*)"maxCount", &InverseMagneticBillard::maxCount, 1000);
        //register_property((char*)"polygonClosed", &InverseMagneticBillard::polygonClosed, false);
    }

    void InverseMagneticBillard::_process()
    {
        // TODO could do stuff here
    }

    // For each trajectory use polyline to draw it in normal space
    void InverseMagneticBillard::_draw()
    {
        // TODO consider using antialiasing and width
        for (auto& t : trajectories) {
            if (t.trajectoryToDraw.size() > 1)
            {
                draw_polyline(t.trajectoryToDraw, t.trajectoryColor);
            }
            
        }


        for (auto& t : inverseTrajectories) {
            if (t.trajectoryToDraw.size() > 1) {
                draw_polyline(t.trajectoryToDraw, t.trajectoryColor);
            }
        }
        
    }

    void InverseMagneticBillard::clear_polygon()
    {
        polygonClosed = false;
        polygon.clear();
        polygonLength.clear();
        reset_trajectories();
        update();
    }

    void InverseMagneticBillard::add_polygon_vertex(Vector2 vertex)
    {
        if (polygonClosed) {    // if the polygon es closed do nothing
            return;
        }
        
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

    void InverseMagneticBillard::close_polygon()
    {
        if (polygonClosed || polygon.size() < 3) { return; }    // polygon needs to haev at least 3 edges

        polygonLength.push_back(polygonLength.back() + length(polygon.back() - vec2_d(polygon[0])));
        

        polygon.push_back(polygon[0]);
        polygonClosed = true;

        // only update polygon for the trajectories, once polygon is closed
        for (auto& t : trajectories) {
            t.set_polygon(polygon, polygonLength);
        }
        for (auto& t : inverseTrajectories) {
            t.set_polygon(polygon, polygonLength);
        }

        update();
    }

    // in order to change one vertex, we rebuild the entire polygon
    void InverseMagneticBillard::set_polygon_vertex(int index, Vector2 vertex)
    {
        if (index >= polygon.size())
        {
            return;
        }
        std::vector<vec2_d> oldPolygon = polygon;
        oldPolygon[index] = vertex;
        oldPolygon.pop_back();
        clear_polygon();
        for (auto& v : oldPolygon) {
            add_polygon_vertex(v.to_godot());
        }
        close_polygon();
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

    void InverseMagneticBillard::add_inverse_trajectory(Vector2 start, Vector2 dir, Color color)
    {
        InverseTrajectory t = InverseTrajectory();
        t.radius = radius;
        t.maxCount = maxCount;
        t.trajectoryColor = color;

        t.polygon = polygon;
        t.polygonLength = polygonLength;

        t.set_initial_values(vec2_d(start), vec2_d(dir));
        inverseTrajectories.push_back(t);
    }

    void InverseMagneticBillard::add_trajectory_phasespace(Vector2 pos, Color color)
    {
        Trajectory t = Trajectory();
        t.radius = radius;
        t.maxCount = maxCount;
        t.trajectoryColor = color;

        t.polygon = polygon;
        t.polygonLength = polygonLength;

        t.set_initial_values(vec2_d(pos));
        trajectories.push_back(t);
    }

    void InverseMagneticBillard::add_inverse_trajectory_phasespace(Vector2 pos, Color color)
    {
        InverseTrajectory t = InverseTrajectory();
        t.radius = radius;
        t.maxCount = maxCount;
        t.trajectoryColor = color;

        t.polygon = polygon;
        t.polygonLength = polygonLength;

        t.set_initial_values(vec2_d(pos));
        inverseTrajectories.push_back(t);
    }

    void InverseMagneticBillard::remove_trajectory(int index)
    {
        trajectories.erase(trajectories.begin() + index);
        update();
    }

    void InverseMagneticBillard::clear_trajectories()
    {
        trajectories.clear();
        inverseTrajectories.clear();
    }

    Array InverseMagneticBillard::get_trajectories()
    {
        Array ts = Array();
        for (size_t i = 0; i < trajectories.size(); i++)
        {
            ts.push_back(trajectories[i].currentPosition.to_godot());
        }
        return ts;
    }

    Array InverseMagneticBillard::iterate_batch(int batch)
    {
        Array phaseSpace;
        for (auto& t : trajectories)
        {
            phaseSpace.push_back(t.iterate_batch(batch));
        }
    
        update();
        return phaseSpace;
    }

    Array InverseMagneticBillard::iterate_inverse_batch(int batch)
    {
        Array phaseSpace;
        for (auto& t : inverseTrajectories)
        {
            phaseSpace.push_back(t.iterate_batch(batch));
        }
        update();
        return phaseSpace;
    }

    void InverseMagneticBillard::set_initial_values(int index, Vector2 start, Vector2 dir)
    {
        trajectories[index].set_initial_values(start, dir);
        update();
    }

    void InverseMagneticBillard::set_color(int index, Color c)
    {
        trajectories[index].trajectoryColor = c;
        update();
    }

    void InverseMagneticBillard::set_max_count(int index, int newMaxCount)
    {

        if (index >= trajectories.size() || index < 0) {
            Godot::print("trying to set max count of not existing trajecotry");
            return;
        }
        trajectories[index].maxCount = newMaxCount;
    }

    PoolColorArray InverseMagneticBillard::get_trajectory_colors()
    {
        PoolColorArray colors;
        for (const auto& t : trajectories) {
            colors.push_back(t.trajectoryColor);
        }
        return colors;
    }

    void InverseMagneticBillard::set_radius(double r)
    {
        radius = r;
        for (auto& t : trajectories)
        {
            t.radius = r;
            t.reset_trajectory();
        }

        for (auto& i : inverseTrajectories)
        {
            i.radius = r;
            i.reset_trajectory();
        }
        update();
    }

    void InverseMagneticBillard::reset_trajectories()
    {
        for (auto& t : trajectories)
        {
            t.reset_trajectory();
        }
        for (auto& t : inverseTrajectories)
        {
            t.reset_trajectory();
        }
        update();
    }

}
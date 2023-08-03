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
        register_method((char*)"set_direction", &InverseMagneticBillard::set_direction);
        register_method((char*)"set_start", &InverseMagneticBillard::set_start);
        register_method((char*)"reset_trajectory", &InverseMagneticBillard::reset_trajectory);
        //register_method((char*)"iterate", &InverseMagneticBillard::iterate);
        register_method((char*)"iterate_batch", &InverseMagneticBillard::iterate_batch);
        register_property<InverseMagneticBillard, double>((char*)"radius", &InverseMagneticBillard::radius, 1);
        register_property((char*)"maxCount", &InverseMagneticBillard::maxCount, 1000);
        register_property((char*)"batch", &InverseMagneticBillard::batch, 100);
        register_property((char*)"polygonClosed", &InverseMagneticBillard::polygonClosed, false);
        register_property((char*)"trajectoryColor", &InverseMagneticBillard::trajectoryColor, Color(0, 1, 0));
    }

    void InverseMagneticBillard::_process()
    {
        // TODO consider calling iterate_batch() here
    }

    void InverseMagneticBillard::_draw()
    {
        // draw the polygon TODO maybe add width and antialiasing
        // TODO consider not drawing the polygon here, but with gd script in the manager node!
        /*if (polygonToDraw.size() > 1) {
            draw_polyline(polygonToDraw, polygonColor);
        }*/
        

        // draw trajectory
        for (const auto& line : trajectoryLines) {
            draw_line(line[0], line[1], trajectoryColor);
        }
        for (const auto& circle : trajectoryCircles) {
            draw_arc(std::get<0>(circle).to_godot(), radius, std::get<1>(circle), std::get<2>(circle), 20, trajectoryColor);
        }

        // DEGUB
        //for (const auto& point : trajectoryDraw) {
            //draw_circle(point, 20, Color(1, 0, 0));
        //}

    }

    void InverseMagneticBillard::clear_polygon()
    {
        polygonClosed = false;
        polygon = {};
        polygonLength = 0;
        //polygonToDraw = {}; // TODO check if this does not give errors
        reset_trajectory();
        update();
    }

    void InverseMagneticBillard::add_polygon_vertex(Vector2 vertex)
    {
        //Godot::print("add vertex to polygon");
        //Godot::print(vertex);
        if (polygonClosed) {    // if the polygon es closed, remember, that last element of vector is first element.
            polygonClosed = false;
            polygon.pop_back();
            //polygonToDraw.remove(polygonToDraw.size() - 1);
            polygon.push_back(vec2_d(vertex));
            //polygonToDraw.push_back(vertex);
            close_polygon();
        }
        else {
            polygon.push_back(vec2_d(vertex));
            //polygonToDraw.push_back(vertex);
        }
        //update();
    }

    void InverseMagneticBillard::close_polygon()
    {
        if (polygonClosed || polygon.size() < 3) { return; }    // polygon needs to haev at least 3 edges
        polygon.push_back(polygon[0]);
        //polygonToDraw.push_back(polygonToDraw[0]);

        // calculate length of circumferreence of polygon
        polygonLength = 0;
        for (int i = 0; i < polygon.size()-1; i++)
        {
            polygonLength += length(polygon[i] - polygon[i + 1]);
        }
        polygonClosed = true;
        update();
    }

    void InverseMagneticBillard::iterate()
    {
        //Godot::print("iteration point :");
        
        // the line inside the polygon
        vec2_d nextIterate = intersect_polygon_line(currentPosition, currentDirection);
        trajectory.push_back(nextIterate);
        trajectoryLines.push_back({ currentPosition.to_godot(), nextIterate.to_godot() });
        currentPosition = nextIterate;  // direction stays the same

        
        // the cirlce outide the polygon
        auto next = intersect_polygon_circle(currentPosition, currentDirection);
        nextIterate = next.first;
        vec2_d center = next.second;
        double angle = std::atan2(det((currentPosition - center), (nextIterate - center)), dot((currentPosition - center), (nextIterate - center))); // dont touch it magically works
        if (angle < 0)
        {
            trajectoryCircles.push_back({ center, (currentPosition - center).angle(), (currentPosition - center).angle() + angle });
        }
        else
        {
            trajectoryCircles.push_back({ center, (currentPosition - center).angle() + angle, (currentPosition - center).angle() + 2 * M_PI });
        }
        trajectory.push_back(nextIterate);
        currentPosition = nextIterate;
        currentDirection = normalize(vec2_d(-(center - nextIterate).y, (center - nextIterate).x));

        
        count++;
        //trajectoryDraw.push_back(currentPosition.to_godot()); for debugging
    }

    void InverseMagneticBillard::iterate_batch()
    {
        if (count + batch > maxCount) { return; }
        for (size_t i = 0; i < batch; i++)
        {
            iterate();
        }
        update();
    }

    void InverseMagneticBillard::set_direction(Vector2 direction) // direction is not actually the direction, but the point where the direction points to from the current position
    {
        currentDirection = normalize(vec2_d(direction) - currentPosition); // always normaize the direction 
    }

    void InverseMagneticBillard::set_start(Vector2 start)
    {
        if (polygon.size() > 2)
        {
            // projection onto poylgon
            double min_distance = INFINITY;
            for (int i = 0; i < polygon.size() - 1; i++)
            {
                double t = (length_squared(start) - dot(start, polygon[i])) / dot(start, polygon[i + 1] - polygon[i]);
                // snap to corners of edge
                if (t < 0) {
                    t = 0;
                }
                else if (t > 1) {
                    t = 1;
                }
                vec2_d pointProjected = (1 - t) * polygon[i] + t * polygon[i + 1];
                double distance = length_squared(vec2_d(start) - pointProjected);
                if (distance < min_distance) {
                    min_distance = distance;
                    currentPosition = pointProjected;
                }
            }
        }
        else
        {
            currentPosition = start;
        }
        
        trajectory = { currentPosition };
        trajectoryLines = {};
        trajectoryCircles = {};
        update();
    }

    vec2_d InverseMagneticBillard::intersect_polygon_line(vec2_d start, vec2_d dir)
    {
        std::vector<double> intersections;
        for (size_t i = 0; i < polygon.size()-1; i++) // only loop till -1, since we know that polygon closed means that first == last point
        {
            // formula for line line intersection from https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection#Given_two_points_on_each_line_segment
            double denominator = (polygon[i + 1].x - polygon[i].x) * dir.y - (polygon[i + 1].y - polygon[i].y) * dir.x;
            if (abs(denominator) < eps)
            {
                continue; // no intersection possible, since lines near parallel
            }
            double t = ((polygon[i].y - start.y) * dir.x - (polygon[i].x - start.x) * dir.y) / denominator;
            if (0 <= t && t <= 1) // consider adding eps here as well
            {
                double u = ((polygon[i].x - start.x) * (polygon[i].y - polygon[i + 1].y) - (polygon[i].y - start.y) * (polygon[i].x - polygon[i + 1].x)) / denominator;
                if (u>eps) // TODO might need bigger coefficient, since u = 0 is also a solution. Could potentially use additional index to prevent this
                {
                    intersections.push_back(u);
                }
            }
        }
        if (intersections.size() == 0) return vec2_d(0, 0); // if this happens, we got an upsi
        double u = *std::min_element(intersections.begin(), intersections.end());   // calculate the smallest u, since that will be the one with the first intersection (only relevant if polygon not convex)
        return start + u*dir;
    }

    void InverseMagneticBillard::set_radius(double r)
    {
        radius = r;
        reset_trajectory();
    }

    // use formula https://math.stackexchange.com/questions/311921/get-location-of-vector-circle-intersection
    // to return new intersection point and center
    // TODO consider smarter return value
    std::pair<vec2_d, vec2_d> InverseMagneticBillard::intersect_polygon_circle(vec2_d start, vec2_d dir)
    {

        //Godot::print("circle intersection GODOT:");
        vec2_d center = start + radius * vec2_d(dir.y, -dir.x); // center of the circle

        std::vector<vec2_d> intersections;
        // iterate through the kanten of the polygon to calculate also maybe here use index of which kante we are on polygon
        for (size_t i = 0; i < polygon.size() - 1 ; i++)
        {
            vec2_d d = polygon[i + 1] - polygon[i];
            // old
            //double a = length_squared(d);
            //double b = 2 * (polygon[i + 1].x - polygon[i].x) * (polygon[i].x - center.x) + 2 * (polygon[i + 1].y - polygon[i].y) * (polygon[i].y - center.y);
            //double c = length_squared(polygon[i] - center) - radius * radius;
            double a = length_squared(d);
            double b = 2 * dot(polygon[i] - center, d);
            double c = length_squared(center - polygon[i]) - radius * radius;
            double discriminant = b*b - 4*a*c;
            if ( discriminant < eps)
            {
                continue;
            }
            discriminant = std::sqrt(discriminant);
            double t = (-b - discriminant) / (2 * a);  // TODO consider optimising here as well with regards to error cancelations
            if (0 < t && t < 1) { // consider using eps here
                vec2_d intersection = polygon[i] + t * d;
                if (length_squared(intersection - start) > eps) // check if intersection point is different from starting point TODO Maybe something smarte with angle might be possible here
                {
                    intersections.push_back(intersection);
                }
            }
            t = (-b + discriminant) / (2 * a); // also check the other intersection
            if (0 < t && t < 1) { // consider using eps here
                vec2_d intersection = polygon[i] + t * d;
                if (length_squared(intersection - start) > eps)
                {
                    intersections.push_back(intersection);
                }
            }
        }
        // TODO for optimization consider moving this inside the other loop THERE MIGHT BE ERROR HERE
        double smallestAngle = 400;
        double angleStart = (start- center).angle();
        vec2_d intersectionPoint = vec2_d(0, 0);
        for (size_t i = 0; i < intersections.size(); i++)
        {
            double angle = angleStart - (intersections[i] - center).angle() ; // need to do some cursed shit since y is inverted
            if (angle < 0) angle += 2*M_PI; // we need to make sure that we always have positive angles!
            if (angle < smallestAngle) {
                smallestAngle = angle;
                intersectionPoint = intersections[i];
            }
        }

        return std::make_pair(intersectionPoint, center);
    }

    void InverseMagneticBillard::reset_trajectory()
    {
        // TODO safe initial direction
        currentPosition = trajectory[0];
        trajectory = { currentPosition };
        trajectoryLines = {};
        trajectoryCircles = {};
        update();
    }

    

}
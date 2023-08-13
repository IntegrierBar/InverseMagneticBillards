#include "Trajectory.h"
#include <CanvasItem.hpp>

namespace godot {

	Trajectory::Trajectory()
	{
	}

	Trajectory::~Trajectory()
	{
	}


    void Trajectory::set_initial_values(vec2_d start, vec2_d dir)
    {
        // projection onto poylgon
        double min_distance = INFINITY;
        vec2_d pointProjected;
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
            pointProjected = (1 - t) * polygon[i] + t * polygon[i + 1];
            double distance = length_squared(vec2_d(start) - pointProjected);
            if (distance < min_distance) {
                min_distance = distance;
                currentPosition = pointProjected;
                currentIndexOnPolygon = i;
            }
        }

        currentDirection = normalize(dir);  // normalize just in case

        double angle = angle_between(normalize(polygon[currentIndexOnPolygon + 1] - polygon[currentIndexOnPolygon]), currentDirection);
        // TODO need to check if angle positive or negative right now
        phaseSpaceTrajectory = { vec2_d((polygonLength[currentIndexOnPolygon] + length(polygon[currentIndexOnPolygon] - pointProjected)) / polygonLength.back(), abs(angle) / M_PI) };

        count = 0;
        trajectory = { currentPosition };
        trajectoryToDraw = {};
        trajectoryToDraw.push_back(currentPosition.to_godot());
    }

    void Trajectory::set_initial_values(vec2_d pos)
    {
        double distance_left = pos.x * polygonLength.back();
        currentIndexOnPolygon = 0;
        while (distance_left - polygonLength[currentIndexOnPolygon + 1] > 0)
        {
            currentIndexOnPolygon++; 
        }

        currentPosition = polygon[currentIndexOnPolygon] + (distance_left - polygonLength[currentIndexOnPolygon]) * normalize(polygon[currentIndexOnPolygon + 1] - polygon[currentIndexOnPolygon]);

        mat2_d rotator = mat2_d(std::cos(M_PI * pos.y), -std::sin(M_PI * pos.y), std::sin(M_PI * pos.y), std::cos(M_PI * pos.y));
        currentDirection = rotator * normalize(polygon[currentIndexOnPolygon + 1] - polygon[currentIndexOnPolygon]);

        count = 0;
        phaseSpaceTrajectory = { pos };
        trajectory = { currentPosition };
        trajectoryToDraw = {};
        trajectoryToDraw.push_back(currentPosition.to_godot());
    }

    void Trajectory::reset_trajectory()
    {
        if (trajectory.size() > 0)
        {
            currentPosition = trajectory[0];
        }

        if (trajectory.size() > 1) {
            currentDirection = normalize(trajectory[1] - currentPosition);
        }
        double min_distance = INFINITY;
        vec2_d pointProjected;
        for (int i = 0; i < polygon.size() - 1; i++)
        {
            Godot::print("should not reach");
            double t = (length_squared(currentPosition) - dot(currentPosition, polygon[i])) / dot(currentPosition, polygon[i + 1] - polygon[i]);
            // snap to corners of edge
            if (t < 0) {
                t = 0;
            }
            else if (t > 1) {
                t = 1;
            }
            pointProjected = (1 - t) * polygon[i] + t * polygon[i + 1];
            double distance = length_squared(vec2_d(currentPosition) - pointProjected);
            if (distance < min_distance) {
                min_distance = distance;
                currentIndexOnPolygon = i;
            }
        }
        count = 0;
        trajectory.resize(1);
        trajectoryToDraw.resize(1);
        phaseSpaceTrajectory.resize(1);
    }


    Vector2 Trajectory::iterate()
    {
        //Godot::print("iteration point :");

        // the line inside the polygon
        auto intersection = intersect_polygon_line(currentPosition, currentDirection);
        vec2_d nextIterate = intersection.first;
        currentIndexOnPolygon = intersection.second;
        trajectory.push_back(nextIterate);
        if (count < maxCount)
        {
            trajectoryToDraw.push_back(nextIterate.to_godot());   // is done together with the circle
        }
        
        currentPosition = nextIterate;  // direction stays the same

        
        // the cirlce outide the polygon
        vec2_d center = currentPosition + radius * vec2_d(currentDirection.y, -currentDirection.x); // center of the circle
        auto next = intersect_polygon_circle(currentPosition, currentPosition, center);
        nextIterate = next.first;
        currentIndexOnPolygon = next.second;
        //double angle = std::atan2(det((currentPosition - center), (nextIterate - center)), dot((currentPosition - center), (nextIterate - center))); // dont touch it magically works
        if (count < maxCount)
        {
            double angle = angle_between((nextIterate - center), (currentPosition - center));
            if (angle < 0)
            {
                angle += 2 * M_PI;
            }

            int n = int(radius * 20);   // to draw a circle, we draw a regular n-gon. Use radius to dynamically upscale

            // divide angle for step size
            double step = -angle / double(n);
            mat2_d rotation = mat2_d(std::cos(step), -std::sin(step), std::sin(step), std::cos(step));
            vec2_d currentAngle = currentPosition - center; // line from center to point on circle
            for (size_t i = 0; i < n; i++)
            {
                currentAngle = rotation * currentAngle;
                trajectoryToDraw.push_back((currentAngle + center).to_godot());

                // IDEA: rotate start point around circle n times, until done
                /*vec2_d vertex = vec2_d(radius * cos(-2 * M_PI * i / n), radius * sin(-2 * M_PI * i / n)) + center;
                if ((vertex - center).angle() < (currentPosition-center).angle() && (vertex - center).angle() > (nextIterate - center).angle())
                {
                    trajectoryToDraw.push_back(vertex.to_godot());
                }*/
            }
            trajectoryToDraw.push_back(nextIterate.to_godot());
        }
        
        //if (angle < 0)
        //{
        //    trajectoryCircles.push_back({ center, (currentPosition - center).angle(), (currentPosition - center).angle() + angle });
        //}
        //else
        //{
        //    trajectoryCircles.push_back({ center, (currentPosition - center).angle() + angle, (currentPosition - center).angle() + 2 * M_PI });
        //}
        trajectory.push_back(nextIterate);
        
        currentPosition = nextIterate;
        currentDirection = normalize(vec2_d(-(center - nextIterate).y, (center - nextIterate).x));

        double anglePhasespace = angle_between(normalize(polygon[currentIndexOnPolygon + 1] - polygon[currentIndexOnPolygon]), currentDirection);
        double pos = (polygonLength[currentIndexOnPolygon] + length(polygon[currentIndexOnPolygon] - currentPosition)) / polygonLength.back();
        phaseSpaceTrajectory = { vec2_d(pos, abs(anglePhasespace) / M_PI) };
        count++;
        return Vector2(pos, abs(anglePhasespace) / M_PI);
    }

    // iterate batch
    PoolVector2Array Trajectory::iterate_batch(int batch)
    {
        PoolVector2Array coordinatesPhasespace = PoolVector2Array();
        //if (count + batch > maxCount) { 
        //    return coordinatesPhasespace; 
        //}
        coordinatesPhasespace.resize(batch);
        for (size_t i = 0; i < batch; i++)
        {
            coordinatesPhasespace.set(i, iterate());
        }
        return coordinatesPhasespace;
    }

    void Trajectory::set_polygon(std::vector<vec2_d> p, std::vector<double> l)
    {
        polygon = p;
        polygonLength = l;
        if (phaseSpaceTrajectory.size() > 0)
        {
            set_initial_values(phaseSpaceTrajectory[0]);
        }
        
    }

    // return both the point and the index of the intersection edge
    std::pair<vec2_d, int> Trajectory::intersect_polygon_line(vec2_d start, vec2_d dir)
    {
        int index = 0;
        vec2_d intersection = vec2_d(0, 0);
        double min_distance = INFINITY;
        for (size_t i = 0; i < polygon.size() - 1; i++) // only loop till -1, since we know that polygon closed means that first == last point
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
                if (i != currentIndexOnPolygon && u < min_distance && u > 0) // TODO might need bigger coefficient, since u = 0 is also a solution. Could potentially use additional index to prevent this
                {
                    min_distance = u;
                    intersection = start + u * dir; // TODO there could be an error in this
                    index = i;
                }
            }
        }
        // If we don't find any other intersection, then this is because we are at a polygon vertex. In this case just keep going
        if (min_distance == INFINITY)
        {
            return std::make_pair(currentPosition, currentIndexOnPolygon);
        }
        //if (intersections.size() == 0) return std::make_pair(vec2_d(0,0), 0); // if this happens, we got an upsi
        //auto u = std::min_element(intersections.begin(), intersections.end());   // calculate the smallest u, since that will be the one with the first intersection (only relevant if polygon not convex)
        return std::make_pair(intersection, index);
    }

    // use formula https://math.stackexchange.com/questions/311921/get-location-of-vector-circle-intersection
    // to return new intersection point and index of edge
    // TODO consider optimizing!!!!!!
    std::pair<vec2_d, int> Trajectory::intersect_polygon_circle(vec2_d start, vec2_d dir, vec2_d center)
    {

        //Godot::print("circle intersection GODOT:");

        int index = 0;
        vec2_d intersectionPoint = vec2_d(0, 0);
        double smallestAngle = INFINITY;
        double angleStart = (start - center).angle();
        // iterate through the kanten of the polygon to calculate also maybe here use index of which kante we are on polygon
        for (size_t i = 0; i < polygon.size() - 1; i++)
        {
            vec2_d d = polygon[i + 1] - polygon[i];
            // old
            //double a = length_squared(d);
            //double b = 2 * (polygon[i + 1].x - polygon[i].x) * (polygon[i].x - center.x) + 2 * (polygon[i + 1].y - polygon[i].y) * (polygon[i].y - center.y);
            //double c = length_squared(polygon[i] - center) - radius * radius;
            double a = length_squared(d);
            double b = 2 * dot(polygon[i] - center, d);
            double c = length_squared(center - polygon[i]) - radius * radius;
            double discriminant = b * b - 4 * a * c;
            if (discriminant < 0) // maybe need eps here?
            {
                continue;
            }
            discriminant = std::sqrt(discriminant);
            double t = (-b - discriminant) / (2 * a);  // TODO consider optimising here as well with regards to error cancelations
            if (0 <= t && t <= 1) { // consider using eps here
                vec2_d intersection = polygon[i] + t * d;
                if (length_squared(intersection - start) > eps) // check if intersection point is different from starting point TODO Maybe something smarte with angle might be possible here
                {
                    double angle = angleStart - (intersection - center).angle(); // need to do some cursed shit since y is inverted
                    if (angle < 0) angle += 2 * M_PI; // we need to make sure that we always have positive angles!
                    if (angle < smallestAngle) {
                        smallestAngle = angle;
                        intersectionPoint = intersection;
                        index = i;
                    }
                }
            }
            t = (-b + discriminant) / (2 * a); // also check the other intersection
            if (0 <= t && t <= 1) { // consider using eps here
                vec2_d intersection = polygon[i] + t * d;
                if (length_squared(intersection - start) > eps)
                {
                    double angle = angleStart - (intersection - center).angle(); // need to do some cursed shit since y is inverted
                    if (angle < 0) angle += 2 * M_PI; // we need to make sure that we always have positive angles!
                    if (angle < smallestAngle) {
                        smallestAngle = angle;
                        intersectionPoint = intersection;
                        index = i;
                    }
                }
            }
        }
        // TODO for optimization consider moving this inside the other loop THERE MIGHT BE ERROR HERE NO ERROR HERE I THINK
        //double smallestAngle = 400;
        //double angleStart = (start- center).angle();
        //vec2_d intersectionPoint = vec2_d(0, 0);
        //for (size_t i = 0; i < intersections.size(); i++)
        //{
        //    double angle = angleStart - (intersections[i] - center).angle() ; // need to do some cursed shit since y is inverted
        //    if (angle < 0) angle += 2*M_PI; // we need to make sure that we always have positive angles!
        //    if (angle < smallestAngle) {
        //        smallestAngle = angle;
        //        intersectionPoint = intersections[i];
        //    }
        //}

        // we dont find any intersections if the circle intersection directly at a polygon vertex. In this case just return next polygon vertex as intersectionPoint
        if (smallestAngle == INFINITY)
        {
            return std::make_pair(polygon[currentIndexOnPolygon + 1], currentIndexOnPolygon + 1);
        }
        return std::make_pair(intersectionPoint, index);
    }
    
}
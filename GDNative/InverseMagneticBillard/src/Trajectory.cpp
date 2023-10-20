#include "Trajectory.h"
#include <CanvasItem.hpp>
#include <exception>
#include <stdexcept>

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

        // calculate the phase space coordinates
        double angle = angle_between(normalize(polygon[currentIndexOnPolygon + 1] - polygon[currentIndexOnPolygon]), currentDirection);
        phaseSpaceTrajectory = { vec2_d((polygonLength[currentIndexOnPolygon] + length(polygon[currentIndexOnPolygon] - currentPosition)) / polygonLength.back(), abs(angle) / M_PI) };

        count = 0;
        trajectory = { currentPosition };
        trajectoryToDraw = {};
        trajectoryToDraw.push_back(currentPosition.to_draw());
    }

    void Trajectory::set_initial_values(vec2_d pos)
    {
        if (polygonLength.size() < 3)
        {
            Godot::print("tried adding phasespace point, but there is no poly");
            return;
        }
        if (pos.x > 1 || pos.y > 1)
        {
            Godot::print("coords to big");
            return;
        }

        // calculate "currentIndexOnPolygon"
        double distance_left = pos.x * polygonLength.back();
        currentIndexOnPolygon = 0;
        while (distance_left - polygonLength[currentIndexOnPolygon + 1] > 0)
        {
            currentIndexOnPolygon++; 
            if (currentIndexOnPolygon + 1 >= polygonLength.size())
            {
                Godot::print("how defuq did I get here?");
                return;
            }
        }

        currentPosition = polygon[currentIndexOnPolygon] + (distance_left - polygonLength[currentIndexOnPolygon]) * normalize(polygon[currentIndexOnPolygon + 1] - polygon[currentIndexOnPolygon]);

        // get direction by rotating the vector "polygon[currentIndexOnPolygon + 1] - polygon[currentIndexOnPolygon]" by an angle
        // need to find out which direction we need to rotate to rotate inside the polygon
        mat2_d rotator = mat2_d(std::cos(M_PI * pos.y), -std::sin(M_PI * pos.y), std::sin(M_PI * pos.y), std::cos(M_PI * pos.y));
        currentDirection = rotator * normalize(polygon[currentIndexOnPolygon + 1] - polygon[currentIndexOnPolygon]);
        // Use intersection test for this
        vec2_d dir = currentDirection;
        vec2_d start = currentPosition + eps * currentDirection;
        int intersections = 0;
        for (size_t i = 0; i < polygon.size() - 1; i++) // only loop till -1, since we know that polygon closed means that first == last point
        {
            // formula for line line intersection from https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection#Given_two_points_on_each_line_segment
            double denominator = (polygon[i + 1].x - polygon[i].x) * dir.y - (polygon[i + 1].y - polygon[i].y) * dir.x;
            if (abs(denominator) < eps)
            {
                continue; // no intersection possible, since lines near parallel
            }
            double t = ((polygon[i].y - start.y) * dir.x - (polygon[i].x - start.x) * dir.y) / denominator;
            if (0 <= t && t < 1) // allow t = 0 but not t = 1 to avoid double counting
            {
                double u = ((polygon[i].x - start.x) * (polygon[i].y - polygon[i + 1].y) - (polygon[i].y - start.y) * (polygon[i].x - polygon[i + 1].x)) / denominator;
                if (i != currentIndexOnPolygon && u > 0)
                {
                    intersections++;
                }
            }
        }
        // if even amount of intersections, the we went the wrong direction
        if (intersections % 2 == 0)
        {
            mat2_d rotator = mat2_d(std::cos(-M_PI * pos.y), -std::sin(-M_PI * pos.y), std::sin(-M_PI * pos.y), std::cos(-M_PI * pos.y));
            currentDirection = rotator * normalize(polygon[currentIndexOnPolygon + 1] - polygon[currentIndexOnPolygon]);
        }

        count = 0;
        phaseSpaceTrajectory = { pos };
        trajectory = { currentPosition };
        trajectoryToDraw = {};
        trajectoryToDraw.push_back(currentPosition.to_draw());
    }

    void Trajectory::reset_trajectory()
    {
        if (phaseSpaceTrajectory.size() > 0)    // should always be true
        {
            //currentPosition = trajectory[0];
            set_initial_values(phaseSpaceTrajectory[0]);
        }
    }


    std::optional<Vector2> Trajectory::iterate()
    {
        // First part: intersect polygon with line
        auto intersectionOpt = intersect_polygon_line(currentPosition, currentDirection);
        if (!intersectionOpt)
        {
            // if the intersection failed, stop the iteration by setting count to maxIter and return nullopt to tell the calling code
            count = maxIter;
            return std::nullopt;
        }

        auto& intersection = *intersectionOpt;
        vec2_d nextIterate = intersection.first;
        currentIndexOnPolygon = intersection.second;
        if (currentIndexOnPolygon >= polygon.size() - 1)
        {
            Godot::print("currentIndexOnPolygon is to large on first occasion");   // todo check if this acutally ever happens
            return Vector2(0, 0);
        }
        if (count < maxCount)   //draw in normal space if desired
        {
            trajectoryToDraw.push_back(nextIterate.to_draw());
        }
        
        currentPosition = nextIterate;  // direction stays the same

        
        // Second part: intersect polygon with circle
        vec2_d center = currentPosition + radius * vec2_d(-currentDirection.y, currentDirection.x); // center of the circle
        auto secondIntersectionOpt = intersect_polygon_circle(currentPosition, currentDirection, center);
        if (!secondIntersectionOpt)
        {
            // if the intersection failed, stop the iteration by setting count to maxIter and return nullopt to tell the calling code
            count = maxIter;
            return std::nullopt;
        }
        auto& next = *secondIntersectionOpt;
        nextIterate = next.first;
        currentIndexOnPolygon = next.second;
        if (currentIndexOnPolygon >= polygon.size() - 1)
        {
            Godot::print("currentIndexOnPolygon is to large on second occasion");
            return Vector2(0, 0);
        }

        if (count < maxCount)   //draw in normal space if desired
        {
            // To draw a circle we take the current position and rotate it n times by a small step around the center

            double angle = angle_between((currentPosition - center), (nextIterate - center));
            if (angle < 0)
            {
                angle += 2 * M_PI;      // need angle counter clockwise, i.e. no negative angles
            }

            int n = 20; 

            // divide angle for step size
            double step = angle / double(n);
            mat2_d rotation = mat2_d(std::cos(step), -std::sin(step), std::sin(step), std::cos(step));
            vec2_d currentAngle = currentPosition - center; // line from center to point on circle
            for (size_t i = 0; i < n; i++)
            {
                currentAngle = rotation * currentAngle;
                trajectoryToDraw.push_back((currentAngle + center).to_draw());
            }
            trajectoryToDraw.push_back(nextIterate.to_draw());
        }

        trajectory.push_back(nextIterate);
        
        currentPosition = nextIterate;
        currentDirection = normalize(vec2_d((center - nextIterate).y, -(center - nextIterate).x));

        // calculate phase space coordinates
        double anglePhasespace = angle_between(normalize(polygon[currentIndexOnPolygon + 1] - polygon[currentIndexOnPolygon]), currentDirection);
        double pos = (polygonLength[currentIndexOnPolygon] + length(polygon[currentIndexOnPolygon] - currentPosition)) / polygonLength.back();
        phaseSpaceTrajectory.push_back(vec2_d(pos, abs(anglePhasespace) / M_PI) );
        count++;
        return Vector2(pos, abs(anglePhasespace) / M_PI);
    }

    // iterate batch
    PoolVector2Array Trajectory::iterate_batch(int batch)
    {
        PoolVector2Array coordinatesPhasespace = PoolVector2Array();
        // do checks to make sure that everything is valid
        if (polygon.size() < 3)
        {
            Godot::print("polygon not enough vertices");
            return coordinatesPhasespace;
        }
        if (polygon.size() != polygonLength.size())
        {
            Godot::print("polygon structures not of same size");
            Godot::print(Vector2(polygon.size(), polygonLength.size()));
            return coordinatesPhasespace;
        }
        if (length_squared(polygon[0] - polygon.back()) > eps)
        {
            Godot::print("polygon not closed");
            Godot::print(polygon[0].to_godot());
            Godot::print(polygon.back().to_godot());
            return coordinatesPhasespace;
        }

        if (count >= maxIter)
        {
            return coordinatesPhasespace;
        }

        batch = std::min(batch, maxIter - count);   // make sure we don't iterate to far
        
        coordinatesPhasespace.resize(batch);
        for (size_t i = 0; i < batch; i++)
        {
            if (auto point = iterate())
            {
                coordinatesPhasespace.set(i, *point);
            }
            else
            {
                // if we got a nullopt, we stop
                Godot::print("got nullopt from iteration");
                break;  
            }
        }
        return coordinatesPhasespace;
    }

    std::optional<Vector2> Trajectory::iterate_symplectic()
    {
        // first intersect polygon with new line to get next position.
        auto intersectionOpt = intersect_polygon_line(currentPosition, currentDirection);
        if (!intersectionOpt)
        {
            // if the intersection failed, stop the iteration by setting count to maxIter and return nullopt to tell the calling code
            count = maxIter;
            return std::nullopt;
        }
        auto& intersection = *intersectionOpt;
        auto nextIterate = intersection.first;
        // get new direction by calculating the next iterate by intersecting the polygon with line from old position with direction of the edge of the polygon of the new position
        vec2_d dir = normalize(polygon[intersection.second + 1] - polygon[intersection.second]);
        // still have to find out in which direction we need to go
        // Use intersection test for this
        vec2_d start = currentPosition + eps * currentDirection;
        int intersections = 0;
        for (size_t i = 0; i < polygon.size() - 1; i++) // only loop till -1, since we know that polygon closed means that first == last point
        {
            // formula for line line intersection from https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection#Given_two_points_on_each_line_segment
            double denominator = (polygon[i + 1].x - polygon[i].x) * dir.y - (polygon[i + 1].y - polygon[i].y) * dir.x;
            if (abs(denominator) < eps)
            {
                continue; // no intersection possible, since lines near parallel
            }
            double t = ((polygon[i].y - start.y) * dir.x - (polygon[i].x - start.x) * dir.y) / denominator;
            if (0 <= t && t < 1) // allow t = 0 but not t = 1 to avoid double counting
            {
                double u = ((polygon[i].x - start.x) * (polygon[i].y - polygon[i + 1].y) - (polygon[i].y - start.y) * (polygon[i].x - polygon[i + 1].x)) / denominator;
                if (i != currentIndexOnPolygon && u > 0)
                {
                    intersections++;
                }
            }
        }
        if (intersections % 2 == 0)
        {
            dir = -dir;
        }

        auto secondIntersectionOpt = intersect_polygon_line(currentPosition, dir);
        if (!secondIntersectionOpt)
        {
            // if the intersection failed, stop the iteration by setting count to maxIter and return nullopt to tell the calling code
            count = maxIter;
            return std::nullopt;
        }

        auto& secondIntersection = *secondIntersectionOpt;
        currentIndexOnPolygon = intersection.second;
        currentPosition = nextIterate;
        currentDirection = normalize(secondIntersection.first - currentPosition);


        if (count < maxCount)   //draw in normal space if desired
        {
            trajectoryToDraw.push_back(currentPosition.to_draw());
        }

        // calculate phase space coordinates
        double anglePhasespace = angle_between(normalize(polygon[currentIndexOnPolygon + 1] - polygon[currentIndexOnPolygon]), currentDirection);
        double pos = (polygonLength[currentIndexOnPolygon] + length(polygon[currentIndexOnPolygon] - currentPosition)) / polygonLength.back();
        phaseSpaceTrajectory.push_back(vec2_d(pos, abs(anglePhasespace) / M_PI));
        count++;
        return { Vector2(pos, abs(anglePhasespace) / M_PI) };
    }

    PoolVector2Array Trajectory::iterate_symplectic_batch(int batch)
    {
        PoolVector2Array coordinatesPhasespace = PoolVector2Array();
        // do checks to make sure that everything is valid
        if (polygon.size() < 3)
        {
            Godot::print("polygon not enough vertices");
            return coordinatesPhasespace;
        }
        if (polygon.size() != polygonLength.size())
        {
            Godot::print("polygon structures not of same size");
            Godot::print(Vector2(polygon.size(), polygonLength.size()));
            return coordinatesPhasespace;
        }
        if (length_squared(polygon[0] - polygon.back()) > eps)
        {
            Godot::print("polygon not closed");
            Godot::print(polygon[0].to_godot());
            Godot::print(polygon.back().to_godot());
            return coordinatesPhasespace;
        }

        if (count >= maxIter)
        {
            return coordinatesPhasespace;
        }

        batch = std::min(batch, maxIter - count);   // make sure we don't iterate to far

        coordinatesPhasespace.resize(batch);
        for (size_t i = 0; i < batch; i++)
        {
            if (auto point = iterate_symplectic())
            {
                coordinatesPhasespace.set(i, *point);
            }
            else
            {
                // if we got a nullopt, we stop
                break;
            }
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
    // formula for line line intersection from https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection#Given_two_points_on_each_line_segment
    // iterates through the polygon and does line line intersection for every edge to find closest intersection
    std::optional<std::pair<vec2_d, int>>Trajectory::intersect_polygon_line(vec2_d start, vec2_d dir)
    {
        int index = 0;
        vec2_d intersection = vec2_d(0, 0);
        double min_distance = INFINITY;
        for (size_t i = 0; i < polygon.size() - 1; i++) // only loop till -1, since we know that polygon closed means that first == last point
        {
            double denominator = (polygon[i + 1].x - polygon[i].x) * dir.y - (polygon[i + 1].y - polygon[i].y) * dir.x;
            if (abs(denominator) < eps)
            {
                continue; // no intersection possible, since lines near parallel
            }
            double t = ((polygon[i].y - start.y) * dir.x - (polygon[i].x - start.x) * dir.y) / denominator;
            if (0 <= t && t <= 1) // consider adding eps here as well
            {
                double u = ((polygon[i].x - start.x) * (polygon[i].y - polygon[i + 1].y) - (polygon[i].y - start.y) * (polygon[i].x - polygon[i + 1].x)) / denominator;
                if (i != currentIndexOnPolygon && u < min_distance && u > 0)
                {
                    min_distance = u;
                    intersection = start + u * dir;
                    index = i;
                }
            }
        }
        // If we don't find any other intersection, then this is because we are at a polygon vertex. In this case just keep going
        if (min_distance == INFINITY)
        {
            Godot::print("could not intersect polygon with line");
            return std::nullopt;
        }

        return { std::make_pair(intersection, index) };
    }

    // use formula https://math.stackexchange.com/questions/311921/get-location-of-vector-circle-intersection
    // to return new intersection point and index of edge
    // iterates through the polygon and does line circle intersection for every edge to find the first intersection
    std::optional<std::pair<vec2_d, int>> Trajectory::intersect_polygon_circle(vec2_d start, vec2_d dir, vec2_d center)
    {
        int index = 0;
        vec2_d intersectionPoint = vec2_d(0, 0);
        double smallestAngle = INFINITY;
        double angleStart = (start - center).angle();
        // consider using knowledge of currentIndexOnPolygon
        for (size_t i = 0; i < polygon.size() - 1; i++)
        {
            vec2_d d = polygon[i + 1] - polygon[i];
            double a = length_squared(d);
            double b = 2 * dot(polygon[i] - center, d);
            double c = length_squared(center - polygon[i]) - radius * radius;
            double discriminant = b * b - 4 * a * c;
            if (discriminant < 0) // maybe need eps here?
            {
                continue;
            }
            discriminant = std::sqrt(discriminant);
            double t = (-b - discriminant) / (2 * a); 
            if (0 <= t && t <= 1) { // consider using eps here
                vec2_d intersection = polygon[i] + t * d;
                if (length_squared(intersection - start) > eps) // check if intersection point is different from starting point
                {
                    double angle = (intersection - center).angle() - angleStart;
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
                    double angle = (intersection - center).angle() - angleStart;
                    if (angle < 0) angle += 2 * M_PI; // we need to make sure that we always have positive angles!
                    if (angle < smallestAngle) {
                        smallestAngle = angle;
                        intersectionPoint = intersection;
                        index = i;
                    }
                }
            }
        }

        // sanity check
        if (smallestAngle == INFINITY)
        {
            Godot::print("could not intersect polygon and circle");
            return std::nullopt;
        }
        return { std::make_pair(intersectionPoint, index) };
    }
    
}
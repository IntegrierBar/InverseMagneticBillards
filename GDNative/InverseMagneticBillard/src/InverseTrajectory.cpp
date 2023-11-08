#include "InverseTrajectory.h"

namespace godot {

    std::optional<Vector2> InverseTrajectory::iterate()
    {
        // First part: polygon circle intersection
        vec2_d center = currentPosition + radius * vec2_d(-currentDirection.y, currentDirection.x); // center of the circle 
        auto next = intersect_polygon_circle(currentPosition, currentDirection, center);
        auto nextIterate = next.first;

        // for drawing the trajectory
        if (count < maxCount)
        {
            // To draw a circle we take the current position and rotate it n times by a small step around the center
            double angle = angle_between((nextIterate - center), (currentPosition - center));
            if (angle < 0)
            {
                angle += 2 * M_PI;
            }

            int n = int(radius * 20);

            // divide angle for step size MAKE SURE TO GO RIGHT DIRECTION
            double step = - angle / double(n);
            mat2_d rotation = mat2_d(std::cos(step), -std::sin(step), std::sin(step), std::cos(step));
            vec2_d currentAngle = currentPosition - center; // line from center to point on circle
            for (size_t i = 0; i < n; i++)
            {
                currentAngle = rotation * currentAngle;
                trajectoryToDraw[0].push_back((currentAngle + center).to_draw());
            }
            trajectoryToDraw[0].push_back(nextIterate.to_draw());
        }
        currentIndexOnPolygon = next.second;
        currentPosition = nextIterate;
        currentDirection = normalize(vec2_d((center - nextIterate).y, -(center - nextIterate).x));



        // Second part: polygon line intersection
        auto intersection = intersect_polygon_line(currentPosition, currentDirection);
        nextIterate = intersection.first;
        // for drawing
        if (count < maxCount)
        {
            trajectoryToDraw[0].push_back(nextIterate.to_draw());
        }

        currentIndexOnPolygon = intersection.second;
        currentPosition = nextIterate;  // direction stays the same

        // calculate phase space coordinates
        double anglePhasespace = angle_between(normalize(polygon[currentIndexOnPolygon + 1] - polygon[currentIndexOnPolygon]), currentDirection);
        double pos = (polygonLength[currentIndexOnPolygon] + length(polygon[currentIndexOnPolygon] - currentPosition)) / polygonLength.back();

        phaseSpaceTrajectory.push_back( vec2_d(pos, abs(anglePhasespace) / M_PI) );
        trajectory.push_back(nextIterate);

        count++;
        return { Vector2(pos, abs(anglePhasespace) / M_PI) };
    }

    PoolVector2Array InverseTrajectory::iterate_batch(int batch)
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

    std::optional<Vector2> InverseTrajectory::iterate_symplectic()
    {
        // first intersect polygon with new line to get next position.
        // then using this get the original position
        auto intersectionOpt = Trajectory::intersect_polygon_line(currentPosition, currentDirection);   // use function from baseclass
        if (!intersectionOpt)
        {
            // if the intersection failed, stop the iteration by setting count to maxIter and return nullopt to tell the calling code
            count = maxIter;
            return std::nullopt;
        }
        auto& intersection = *intersectionOpt;
        auto nextIterate = intersection.first;
        // get previous position by calculating by intersecting the polygon with line from next position with direction of the edge of the polygon of the current position
        vec2_d dir = normalize(polygon[currentIndexOnPolygon] - polygon[currentIndexOnPolygon + 1]);
        // still have to find out in which direction we need to go
        // Use intersection test for this
        vec2_d start = nextIterate + 100 * eps * dir;
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

        auto secondIntersectionOpt = Trajectory::intersect_polygon_line(nextIterate, dir);
        if (!secondIntersectionOpt)
        {
            // if the intersection failed, stop the iteration by setting count to maxIter and return nullopt to tell the calling code
            count = maxIter;
            return std::nullopt;
        }

        auto& secondIntersection = *secondIntersectionOpt;
        currentIndexOnPolygon = secondIntersection.second;
        currentDirection = normalize(currentPosition - secondIntersection.first);
        currentPosition = secondIntersection.first;


        if (count < maxCount)   //draw in normal space if desired
        {
            trajectoryToDraw[0].push_back(currentPosition.to_draw());
        }

        // calculate phase space coordinates
        double anglePhasespace = angle_between(normalize(polygon[currentIndexOnPolygon + 1] - polygon[currentIndexOnPolygon]), currentDirection);
        double pos = (polygonLength[currentIndexOnPolygon] + length(polygon[currentIndexOnPolygon] - currentPosition)) / polygonLength.back();
        phaseSpaceTrajectory.push_back(vec2_d(pos, abs(anglePhasespace) / M_PI));
        count++;
        return { Vector2(pos, abs(anglePhasespace) / M_PI) };
    }

    PoolVector2Array InverseTrajectory::iterate_symplectic_batch(int batch)
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

    // both function work like in "Trajectory" but instead of minimizing the length/angle, they maximize it
    std::pair<vec2_d, int> InverseTrajectory::intersect_polygon_line(vec2_d start, vec2_d dir)
    {
        int index = 0;
        vec2_d intersection = vec2_d(0, 0);
        double min_distance = -INFINITY;
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
                if (i != currentIndexOnPolygon && u > min_distance && u < 0) // u has to be negative here since we are walking backwards
                {
                    min_distance = u;
                    intersection = start + u * dir;
                    index = i;
                }
            }
        }
        
        if (min_distance == -INFINITY)
        {
            // ideally this code should never execute. If it does, the program wont crash, but the calculations are wrong
            Godot::print("could not intersect polygon with line");
            return std::make_pair(currentPosition, currentIndexOnPolygon);
        }

        return std::make_pair(intersection, index);
    }
    std::pair<vec2_d, int> InverseTrajectory::intersect_polygon_circle(vec2_d start, vec2_d dir, vec2_d center)
    {
        int index = 0;
        vec2_d intersectionPoint = vec2_d(0, 0);
        double largestAngle = 0;    // Here we want to find the smallest angle, as then the angle to our current position is minimal. Initialise with 0 since angles always positive here
        double angleStart = (start - center).angle();
        // iterate through the kanten of the polygon to calculate
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
                    if (angle > largestAngle) {
                        largestAngle = angle;
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
                    double angle = (intersection - center).angle() - angleStart; // need to do some cursed shit since y is inverted NOT ANYMORE
                    if (angle < 0) angle += 2 * M_PI; // we need to make sure that we always have positive angles!
                    if (angle > largestAngle) {
                        largestAngle = angle;
                        intersectionPoint = intersection;
                        index = i;
                    }
                }
            }
        }

        // we dont find any intersections if the circle intersection directly at a polygon vertex. In this case just return next polygon vertex as intersectionPoint
        if (largestAngle == 0)
        {
            Godot::print("could not intersect polygon and circle");
            return std::make_pair(polygon[currentIndexOnPolygon + 1], currentIndexOnPolygon + 1);
        }
        return std::make_pair(intersectionPoint, index);
    }
    
}

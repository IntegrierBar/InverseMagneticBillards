#include "InverseTrajectory.h"

namespace godot {

	void InverseTrajectory::set_initial_values(vec2_d start, vec2_d dir)
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

	void InverseTrajectory::set_initial_values(vec2_d pos)
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

        double distance_left = pos.x * polygonLength.back();
        currentIndexOnPolygon = 0;
        while (distance_left - polygonLength[currentIndexOnPolygon + 1] > 0)
        {
            //Godot::print(Vector2(currentIndexOnPolygon, 0));
            currentIndexOnPolygon++;
            if (currentIndexOnPolygon + 1 >= polygonLength.size())
            {
                Godot::print("how defuq did I get here?");
                return;
            }
        }

        currentPosition = polygon[currentIndexOnPolygon] + (distance_left - polygonLength[currentIndexOnPolygon]) * normalize(polygon[currentIndexOnPolygon + 1] - polygon[currentIndexOnPolygon]);

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
        trajectoryToDraw.push_back(currentPosition.to_godot());
	}

	void InverseTrajectory::reset_trajectory()
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
        currentIndexOnPolygon = 0; // does not fix the problem. can delete or keep whatever, I hate this. Rust is better
        for (int i = 0; i < polygon.size() - 1; i++)
        {
            //Godot::print("should not reach");
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
        phaseSpaceTrajectory.resize(1);
        trajectoryToDraw.resize(1);
	}

    void InverseTrajectory::set_polygon(std::vector<vec2_d> p, std::vector<double> l)
    {
        polygon = p;
        polygonLength = l;
        if (phaseSpaceTrajectory.size() > 0)
        {
            set_initial_values(phaseSpaceTrajectory[0]);
        }
    }

    Vector2 InverseTrajectory::iterate()
    {
        // the cirlce outide the polygon
        vec2_d center = currentPosition + radius * vec2_d(currentDirection.y, -currentDirection.x); // center of the circle //TODO
        auto next = intersect_polygon_circle(currentPosition, currentDirection, center);
        auto nextIterate = next.first;

        currentIndexOnPolygon = next.second;
        currentPosition = nextIterate;
        currentDirection = normalize(vec2_d(-(center - nextIterate).y, (center - nextIterate).x));
        // for drawing the trajectory
        if (count < maxCount)
        {
            double angle = angle_between((nextIterate - center), (currentPosition - center));
            if (angle < 0)
            {
                angle += 2 * M_PI;
            }

            int n = int(radius * 20);   // to draw a circle, we draw a regular n-gon. Use radius to dynamically upscale

            // divide angle for step size MAKE SURE TO GO RIGHT DIRECTION
            double step = angle / double(n);
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



        // the line inside the polygon
        auto intersection = intersect_polygon_line(currentPosition, currentDirection);
        nextIterate = intersection.first;

        currentIndexOnPolygon = intersection.second;
        currentPosition = nextIterate;  // direction stays the same

        // add new point to trajectories
        double anglePhasespace = angle_between(normalize(polygon[currentIndexOnPolygon + 1] - polygon[currentIndexOnPolygon]), currentDirection);
        double pos = (polygonLength[currentIndexOnPolygon] + length(polygon[currentIndexOnPolygon] - currentPosition)) / polygonLength.back();

        phaseSpaceTrajectory.push_back( vec2_d(pos, abs(anglePhasespace) / M_PI) );
        trajectory.push_back(nextIterate);

        count++;


        return Vector2(pos, abs(anglePhasespace) / M_PI);
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


        coordinatesPhasespace.resize(batch);
        for (size_t i = 0; i < batch; i++)
        {
            coordinatesPhasespace.set(i, iterate());
        }
        return coordinatesPhasespace;
    }
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
                    intersection = start + u * dir; // TODO there could be an error in this
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
        return std::pair<vec2_d, int>();
    }
}

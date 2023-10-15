#include "SymplecticTrajectory.h"

namespace godot {

	Vector2 godot::SymplecticTrajectory::iterate()
	{
		// first intersect polygon with new line to get next position.
		auto intersection = intersect_polygon_line(currentPosition, currentDirection);
		auto nextIterate = intersection.first;
		currentIndexOnPolygon = intersection.second;
		// get new direction by calculating the next iterate by intersecting the polygon with line from old position with direction of the edge of the polygon of the new position
		vec2_d direction = polygon[currentIndexOnPolygon + 1] - polygon[currentIndexOnPolygon];
		auto secondIntersection = intersect_polygon_line(currentPosition, direction);
		
		currentPosition = nextIterate;
		currentDirection = normalize(secondIntersection.first - currentPosition);


		if (count < maxCount)   //draw in normal space if desired
		{
			trajectoryToDraw.push_back(nextIterate.to_draw());
		}
		
		// calculate phase space coordinates
		double anglePhasespace = angle_between(normalize(polygon[currentIndexOnPolygon + 1] - polygon[currentIndexOnPolygon]), currentDirection);
		double pos = (polygonLength[currentIndexOnPolygon] + length(polygon[currentIndexOnPolygon] - currentPosition)) / polygonLength.back();
		phaseSpaceTrajectory.push_back(vec2_d(pos, abs(anglePhasespace) / M_PI));
		count++;
		Godot::print(Vector2(pos, abs(anglePhasespace) / M_PI));
		return Vector2(pos, abs(anglePhasespace) / M_PI);
	}

	PoolVector2Array godot::SymplecticTrajectory::iterate_batch(int batch)
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
		Godot::print(Vector2(batch, 0));

		coordinatesPhasespace.resize(batch);
		for (size_t i = 0; i < batch; i++)
		{
			coordinatesPhasespace.set(i, iterate());
		}
		return coordinatesPhasespace;
	}

}
shader_type canvas_item;

uniform float radius;
uniform int n;	// largest index of polygon
uniform sampler2D polygon; // need to pass polygon as texture since arrays cant be passed in godot 3
uniform sampler2D polygonLength;

uniform int iterations; 	// how many iterations should be done
uniform bool forwards;		// should we iterate forwards or backwards?
uniform bool showPosition;	// determine if Position should be added to COLOR
uniform bool showAngle;		// determine if Agnle should be added to COLOR


const float M_PI = 3.14159265;
const float eps = 1e-6;


// functions to access points from polygon and polygonLength
vec2 getPolyVertex(int i) {
	return texelFetch(polygon, ivec2(i,0), 0).xy;
}

float getPolyLength(int i) {
	return texelFetch(polygonLength, ivec2(i,0), 0).x;
}

float angle_between(vec2 v1, vec2 v2) {
	return atan(determinant(mat2(v1, v2)), dot(v1, v2));
}


// calculates start and dir from phasespace coords
// same code as in C++ code
// first 2 elements of the return are start other 2 are direction
mat3 phaseSpaceToR2 (vec2 pos) {
	float distance_left = pos.x * getPolyLength(n-1);
	int currentIndexOnPolygon = 0;
	while ( distance_left - getPolyLength(currentIndexOnPolygon + 1) > 0.0)
	{
	    //Godot::print(Vector2(currentIndexOnPolygon, 0));
	    currentIndexOnPolygon++;
		if (currentIndexOnPolygon + 1 > n)
		{
			//Godot::print("how defuq did I get here?");
			break;
		}
	}

	vec2 currentPosition = getPolyVertex(currentIndexOnPolygon) + (distance_left - getPolyLength(currentIndexOnPolygon)) * normalize(getPolyVertex(currentIndexOnPolygon + 1) - getPolyVertex(currentIndexOnPolygon));
	// need to find out which direction we need to rotate to rotate inside the polygon
	mat2 rotator = mat2(vec2(cos(M_PI * pos.y), sin(M_PI * pos.y)), vec2(-sin(M_PI * pos.y), cos(M_PI * pos.y)));	// TODO CHECK
	vec2 currentDirection = rotator * normalize(getPolyVertex(currentIndexOnPolygon + 1) - getPolyVertex(currentIndexOnPolygon));
	// Use intersection test for this
	vec2 dir = currentDirection;
	vec2 start = currentPosition + 1e-6 * currentDirection;
	int intersections = 0;
	for (int i = 0; i < n - 1; i++) // only loop till -1, since we know that polygon closed means that first == last point
	{
	    // formula for line line intersection from https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection#Given_two_points_on_each_line_segment
	    float denominator = (getPolyVertex(i + 1).x - getPolyVertex(i).x) * dir.y - (getPolyVertex(i + 1).y - getPolyVertex(i).y) * dir.x;
	    if (abs(denominator) < 1e-8)
	    {
	        continue; // no intersection possible, since lines near parallel
	    }
	    float t = ((getPolyVertex(i).y - start.y) * dir.x - (getPolyVertex(i).x - start.x) * dir.y) / denominator;
	    if (0.0 <= t && t < 1.0) // allow t = 0 but not t = 1 to avoid double counting
	    {
	        float u = ((getPolyVertex(i).x - start.x) * (getPolyVertex(i).y - getPolyVertex(i + 1).y) - (getPolyVertex(i).y - start.y) * (getPolyVertex(i).x - getPolyVertex(i + 1).x)) / denominator;
	        if (i != currentIndexOnPolygon && u > 0.0)
	        {
	            intersections++;
	        }
	    }
	}
	// if even amount of intersections, the we went the wrong direction
	if (intersections % 2 == 0)
	{
		rotator = mat2(vec2(cos(-M_PI * pos.y), sin(-M_PI * pos.y)), vec2(-sin(-M_PI * pos.y), cos(-M_PI * pos.y)));	// TODO CHECK
	    currentDirection = rotator * normalize(getPolyVertex(currentIndexOnPolygon + 1) - getPolyVertex(currentIndexOnPolygon));
	}
	
	return mat3(vec3(currentPosition, 0), vec3(currentDirection, 0), vec3(float(currentIndexOnPolygon), 0., 0.));
}

// calculates phasespace coords from 2d coords with knowldedge of which edge we are an the polygon
vec2 R2ToPhaseSpace(vec2 start, vec2 dir, int currentIndexOnPolygon) {
	float angle = angle_between(normalize(getPolyVertex(currentIndexOnPolygon + 1) - getPolyVertex(currentIndexOnPolygon)), dir);
	// TODO need to check if angle positive or negative right now
	return vec2( (getPolyLength(currentIndexOnPolygon) + length(getPolyVertex(currentIndexOnPolygon) - start)) / getPolyLength(n-1), abs(angle) / M_PI );
}

// first two are the point, third is the index
// direction either +1 or -1, handles going forward and backward
vec3 intersect_polygon_line(vec2 start, vec2 dir, int currentIndexOnPolygon, float direction) {
    int index = 0;
    vec2 intersection = vec2(0, 0);
    float min_distance = 1e20;	// infitnity basically
    for (int i = 0; i < n - 1; i++) // only loop till -1, since we know that polygon closed means that first == last point
    {
        // formula for line line intersection from https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection#Given_two_points_on_each_line_segment
        float denominator = (getPolyVertex(i + 1).x - getPolyVertex(i).x) * dir.y - (getPolyVertex(i + 1).y - getPolyVertex(i).y) * dir.x;
        if (abs(denominator) < eps)
        {
            continue; // no intersection possible, since lines near parallel
        }
        float t = ((getPolyVertex(i).y - start.y) * dir.x - (getPolyVertex(i).x - start.x) * dir.y) / denominator;
        if (0.0 <= t && t <= 1.0) // consider adding eps here as well
        {
            float u = ((getPolyVertex(i).x - start.x) * (getPolyVertex(i).y - getPolyVertex(i + 1).y) - (getPolyVertex(i).y - start.y) * (getPolyVertex(i).x - getPolyVertex(i + 1).x)) / denominator;
            if (i != currentIndexOnPolygon && u*direction < min_distance && u*direction > 0.0) // u has to be negative here since we are walking backwards
            {
                min_distance = u*direction;
                intersection = start + u * dir;
                index = i;
            }
        }
    }
    
    if (min_distance == 1e20)
    {
        // ideally this code should never execute. If it does, the program wont crash, but the calculations are wrong
        //Godot::print("could not intersect polygon with line");
        return vec3(0.0);
    }

    return vec3(intersection, float(index));
}

// first two are the point, third is the index
vec3 intersect_polygon_circle(vec2 start, vec2 dir, vec2 center, float direction) {
    int index = 0;
    vec2 intersectionPoint = vec2(0, 0);
    float largestAngle = 400.0;    // Here we want to find the smallest angle, as then the angle to our current position is minimal. Initialise with 0 since angles always positive here
    //if (direction > 0.) { largestAngle = 400.;} // allowing both forward and backward iteration
	//float angleStart = (start - center).angle(); NO NEED TO USE THIS; USE ANGLE_BETWEEN()
    // iterate through the kanten of the polygon to calculate
    for (int i = 0; i < n - 1; i++)
    {
        vec2 d = getPolyVertex(i + 1) - getPolyVertex(i);
        float a = dot(d, d);	// = length_squared
        float b = 2.0 * dot(getPolyVertex(i) - center, d);
        float c = dot(center - getPolyVertex(i), center - getPolyVertex(i)) - radius * radius;
        float discriminant = b * b - 4.0 * a * c;
        if (discriminant < 0.0) // maybe need eps here?
        {
            continue;
        }
        discriminant = sqrt(discriminant);
        float t = (-b - discriminant) / (2.0 * a);
        if (0. <= t && t <= 1.) { // consider using eps here
            vec2 intersection = getPolyVertex(i) + t * d;
            if (dot(intersection - start, intersection - start) > eps*radius) // check if intersection point is different from starting point
            {
                float angle = angle_between(start - center, intersection - center);	// TODO could be other way around
                if (angle < 0.) angle += 2. * M_PI; // we need to make sure that we always have positive angles!
                if (angle * direction < largestAngle) {
                    largestAngle = angle * direction;
                    intersectionPoint = intersection;
                    index = i;
                }
            }
        }
        t = (-b + discriminant) / (2. * a); // also check the other intersection
        if (0. <= t && t <= 1.) { // consider using eps here
            vec2 intersection = getPolyVertex(i) + t * d;
            if (dot(intersection - start, intersection - start) > eps*radius)
            {
                float angle = angle_between(start - center, intersection - center);	// TODO could be other way around
                if (angle < 0.) angle += 2. * M_PI ; // we need to make sure that we always have positive angles!
                if (angle * direction < largestAngle) {
                    largestAngle = angle * direction;
                    intersectionPoint = intersection;
                    index = i;
                }
            }
        }
    }

    // we dont find any intersections if the circle intersection directly at a polygon vertex. In this case just return next polygon vertex as intersectionPoint
//    if (largestAngle == 0.0)
//    {
//        return vec3(getPolyVertex(currentIndexOnPolygon + 1), float(currentIndexOnPolygon + 1));
//    }
    return vec3(intersectionPoint, float(index));
}

// returns phasespace corrds
vec2 iterateBackwards(vec2 currentPosition, vec2 currentDirection) {
	// the cirlce outide the polygon
	vec2 center = currentPosition + radius * vec2(-currentDirection.y, currentDirection.x); // center of the circle 
	vec3 next = intersect_polygon_circle(currentPosition, currentDirection, center, -1.);
	vec2 nextIterate = next.xy;
	int currentIndexOnPolygon = int(next.z);
	currentPosition = nextIterate;
	currentDirection = normalize(vec2((center - nextIterate).y, -(center - nextIterate).x));


	// the line inside the polygon
	vec3 intersection = intersect_polygon_line(currentPosition, currentDirection, currentIndexOnPolygon, -1.);
	nextIterate = intersection.xy;
	currentIndexOnPolygon = int(intersection.z);
	currentPosition = nextIterate;  // direction stays the same

	return R2ToPhaseSpace(currentPosition, currentDirection, currentIndexOnPolygon);
}

vec2 iterateForwards(vec2 currentPosition, vec2 currentDirection, int currentIndexOnPolygon) {
	vec3 intersection = intersect_polygon_line(currentPosition, currentDirection, currentIndexOnPolygon, 1.);
	vec2 nextIterate = intersection.xy;
	currentIndexOnPolygon = int(intersection.z);
	currentPosition = nextIterate;  // direction stays the same


	// the cirlce outide the polygon
	vec2 center = currentPosition + radius * vec2(-currentDirection.y, currentDirection.x); // center of the circle
	vec3 next = intersect_polygon_circle(currentPosition, currentDirection, center, 1.);
	nextIterate = next.xy;
	currentIndexOnPolygon = int(next.z);
	currentPosition = nextIterate;
	currentDirection = normalize(vec2((center - nextIterate).y, -(center - nextIterate).x));

	return R2ToPhaseSpace(currentPosition, currentDirection, currentIndexOnPolygon);
}

void fragment() {
	vec2 pos = UV;	// phasespace coords are texture coords
	// get start, dir, index
//	mat3 coords = phaseSpaceToR2(pos);
//	vec2 start = coords[0].xy;
//	vec2 dir = coords[1].xy;
//	int index = int(coords[2].x);
	if (forwards) {
		for (int i=0; i < iterations; i++) {
			mat3 coords = phaseSpaceToR2(pos);
			vec2 start = coords[0].xy;
			vec2 dir = coords[1].xy;
			int index = int(coords[2].x);
			pos = iterateForwards(start, dir, index);
		}
	}
	else {
		for (int i=0; i < iterations; i++) {
			mat3 coords = phaseSpaceToR2(pos);
			vec2 start = coords[0].xy;
			vec2 dir = coords[1].xy;
			//int index = int(coords[2].x);
			pos = iterateBackwards(start, dir);
		}
	}
	//vec2 next = iterateBackwards(start, dir);
	//vec2 next = iterateForwards(start, dir, index);
	// DETERMINE COLOR FROM next PHASESPACE COORDS
	//COLOR = texture(TEXTURE, UV + vec2(getPolyLength(n-1)*0.01, 0));
	//COLOR = texture(TEXTURE, UV + getPolyVertex(n)*0.1);
	//COLOR = texture(TEXTURE, UV + next*0.01);
	COLOR = vec4(0., 0., 0., 1.);
	if (showPosition) {
		COLOR += vec4(pos.x, 0., 0., 0.);
	}
	if (showAngle) {
		COLOR += vec4(0., pos.y, 0., 0.);
	}
	//COLOR = texture(TEXTURE, next);
}


//
//float drawLine (vec2 p1, vec2 p2, vec2 uv, float a, float one_px)
//{
//    float r = 0.;
//
//    // get dist between points
//    float d = distance(p1, p2);
//
//    // get dist between current pixel and p1
//    float duv = distance(p1, uv);
//
//    //if point is on line, according to dist, it should match current uv 
//    r = 1.-floor(1.-(a*one_px)+distance (mix(p1, p2, clamp(duv/d, 0., 1.)),  uv));
//
//    return r;
//}
//
//float drawCircle(vec2 p, float d, vec2 uv)
//{
//    return (distance(p, uv) <= d) ? 1. : 0.;
//}
//
//
//void fragment() {
//	//vec2 xy = texelFetch(polygon, ivec2(2,0), 0).xy;
//
//	vec2 uv = UV;
//	float t = TIME*1.5; //Pro Tip™: multipluy time to go faster!
//
//	float polygon_lines = 0.0;
//	for (int i=0; i<n-1; i++) {
//		//vec2 xy = texelFetch(polygon, ivec2(i,0), 0).xy;
//		polygon_lines = polygon_lines + drawLine(texelFetch(polygon, ivec2(i,0), 0).xy, texelFetch(polygon, ivec2(i + 1,0), 0).xy, uv, 2.0, SCREEN_PIXEL_SIZE.x);
//	}
//
//    //in uv space
//	vec2 p1 = vec2(0.5 + sin(t)*.2, 0.25 + cos(t+pi)*.1);
//	vec2 p2 = vec2(0.5 + sin(t+pi)*.2, 0.25 + cos(t)*.1);
//	vec2 p3 = vec2(0.5 + sin(t+pi/2.)*.2, 0.25 + cos(t-.5*pi)*.1);
//	vec2 p4 = vec2(0.5 + sin(t-pi/2.)*.2, 0.25 + cos(t+.5*pi)*.1);
//	vec2 p5 = vec2(0.5 + sin(t)*.2, 0.75 + cos(t+pi)*.1);
//	vec2 p6 = vec2(0.5 + sin(t+pi)*.2, 0.75 + cos(t)*.1);
//	vec2 p7 = vec2(0.5 + sin(t+pi/2.)*.2, 0.75 + cos(t-.5*pi)*.1);
//	vec2 p8 = vec2(0.5 + sin(t-pi/2.)*.2, 0.75 + cos(t+.5*pi)*.1);
//
//
//	float lines = drawLine(p1, p5, uv, 1., SCREEN_PIXEL_SIZE.x)
//	    		  + drawLine(p2, p6, uv, 1., SCREEN_PIXEL_SIZE.x)
//	    		  + drawLine(p1, p3, uv, 1., SCREEN_PIXEL_SIZE.x)
//	    		  + drawLine(p3, p2, uv, 1., SCREEN_PIXEL_SIZE.x)
//	    		  + drawLine(p1, p4, uv, 1., SCREEN_PIXEL_SIZE.x)
//	    		  + drawLine(p4, p2, uv, 1., SCREEN_PIXEL_SIZE.x)
//	    		  + drawLine(p5, p7, uv, 1., SCREEN_PIXEL_SIZE.x)
//	    		  + drawLine(p7, p6, uv, 1., SCREEN_PIXEL_SIZE.x)
//	    		  + drawLine(p6, p8, uv, 1., SCREEN_PIXEL_SIZE.x)
//	    		  + drawLine(p8, p5, uv, 1., SCREEN_PIXEL_SIZE.x)
//	    		  + drawLine(p3, p7, uv, 1., SCREEN_PIXEL_SIZE.x)
//	    		  + drawLine(p4, p8, uv, 1., SCREEN_PIXEL_SIZE.x);
//
//	float d = 0.003;
//	float dots = drawCircle(p1, d, uv)
//				 + drawCircle(p2, d, uv)
//	     		 + drawCircle(p3, d, uv)
//				 + drawCircle(p4, d, uv)
//	     		 + drawCircle(p5, d, uv)
//				 + drawCircle(p6, d, uv)
//	     		 + drawCircle(p7, d, uv)
//				 + drawCircle(p8, d, uv);
//
//	COLOR = vec4(polygon_lines-dots, dots, dots, 1.);
//}
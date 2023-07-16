shader_type canvas_item;

uniform int n;
uniform sampler2D polygon; // need to pass polygon as texture since arrays cant be passed in godot 3

const float pi = 3.14159265;


float drawLine (vec2 p1, vec2 p2, vec2 uv, float a, float one_px)
{
    float r = 0.;
    
    // get dist between points
    float d = distance(p1, p2);
    
    // get dist between current pixel and p1
    float duv = distance(p1, uv);

    //if point is on line, according to dist, it should match current uv 
    r = 1.-floor(1.-(a*one_px)+distance (mix(p1, p2, clamp(duv/d, 0., 1.)),  uv));
        
    return r;
}

float drawCircle(vec2 p, float d, vec2 uv)
{
    return (distance(p, uv) <= d) ? 1. : 0.;
}


void fragment() {
	//vec2 xy = texelFetch(polygon, ivec2(2,0), 0).xy;
	
	vec2 uv = UV;
	float t = TIME*1.5; //Pro Tip™: multipluy time to go faster!
	
	float polygon_lines = 0.0;
	for (int i=0; i<n-1; i++) {
		//vec2 xy = texelFetch(polygon, ivec2(i,0), 0).xy;
		polygon_lines = polygon_lines + drawLine(texelFetch(polygon, ivec2(i,0), 0).xy, texelFetch(polygon, ivec2(i + 1,0), 0).xy, uv, 2.0, SCREEN_PIXEL_SIZE.x)
	}
    
    //in uv space
	vec2 p1 = vec2(0.5 + sin(t)*.2, 0.25 + cos(t+pi)*.1);
	vec2 p2 = vec2(0.5 + sin(t+pi)*.2, 0.25 + cos(t)*.1);
	vec2 p3 = vec2(0.5 + sin(t+pi/2.)*.2, 0.25 + cos(t-.5*pi)*.1);
	vec2 p4 = vec2(0.5 + sin(t-pi/2.)*.2, 0.25 + cos(t+.5*pi)*.1);
	vec2 p5 = vec2(0.5 + sin(t)*.2, 0.75 + cos(t+pi)*.1);
	vec2 p6 = vec2(0.5 + sin(t+pi)*.2, 0.75 + cos(t)*.1);
	vec2 p7 = vec2(0.5 + sin(t+pi/2.)*.2, 0.75 + cos(t-.5*pi)*.1);
	vec2 p8 = vec2(0.5 + sin(t-pi/2.)*.2, 0.75 + cos(t+.5*pi)*.1);


	float lines = drawLine(p1, p5, uv, 1., SCREEN_PIXEL_SIZE.x)
	    		  + drawLine(p2, p6, uv, 1., SCREEN_PIXEL_SIZE.x)
	    		  + drawLine(p1, p3, uv, 1., SCREEN_PIXEL_SIZE.x)
	    		  + drawLine(p3, p2, uv, 1., SCREEN_PIXEL_SIZE.x)
	    		  + drawLine(p1, p4, uv, 1., SCREEN_PIXEL_SIZE.x)
	    		  + drawLine(p4, p2, uv, 1., SCREEN_PIXEL_SIZE.x)
	    		  + drawLine(p5, p7, uv, 1., SCREEN_PIXEL_SIZE.x)
	    		  + drawLine(p7, p6, uv, 1., SCREEN_PIXEL_SIZE.x)
	    		  + drawLine(p6, p8, uv, 1., SCREEN_PIXEL_SIZE.x)
	    		  + drawLine(p8, p5, uv, 1., SCREEN_PIXEL_SIZE.x)
	    		  + drawLine(p3, p7, uv, 1., SCREEN_PIXEL_SIZE.x)
	    		  + drawLine(p4, p8, uv, 1., SCREEN_PIXEL_SIZE.x);

	float d = 0.003;
	float dots = drawCircle(p1, d, uv)
				 + drawCircle(p2, d, uv)
	     		 + drawCircle(p3, d, uv)
				 + drawCircle(p4, d, uv)
	     		 + drawCircle(p5, d, uv)
				 + drawCircle(p6, d, uv)
	     		 + drawCircle(p7, d, uv)
				 + drawCircle(p8, d, uv);

	COLOR = vec4(polygon_lines-dots, dots, dots, 1.);
}
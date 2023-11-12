shader_type canvas_item;

uniform float point_size = 10;

void vertex() {
	POINT_SIZE = 100.;
	COLOR = vec4(1.0, 0.0, 0., 1.);
	VERTEX = vec2(10.);
}

void fragment() {
	COLOR = vec4(1.0, 0.0, 0., 1.);
}
shader_type spatial;

uniform float min_height = 0;
uniform float max_height = 1;
uniform sampler2D terrain_color;

varying float vertex_y;

float inverse_lerp(float minValue, float maxValue, float value) {
	float val = (value - minValue) / (maxValue - minValue);
	return clamp(0.01, 1.0, val);
}

void fragment() {
	float height = vertex_y;
	float position = inverse_lerp(min_height, max_height, height);
	vec3 color = texture(terrain_color, vec2(position, 0)).rgb;
	
	//This line of code creates the low poly effect (I have no ideia how it works)
	NORMAL = -normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	
	ALBEDO = color;
}

void vertex() {
	vertex_y = VERTEX.y;
}
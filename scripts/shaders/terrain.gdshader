shader_type spatial;

uniform float min_height = -50.0;
uniform float max_height = 1;

uniform sampler2D terrain_color;

varying float vertex_y;

float inverse_lerp(float minValue, float maxValue, float value) {
	float val = (value - minValue) / (maxValue - minValue);
	return clamp(val, 0.0, 1.0);
}

void vertex() {
	vec4 world_position = MODEL_MATRIX * vec4(VERTEX, 1.0);
	vertex_y = world_position.y;
}

void fragment() {
	float height = vertex_y;
	float position = inverse_lerp(min_height, max_height, height);

	ALBEDO = texture(terrain_color, vec2(position, 0)).rgb;
	NORMAL = normalize(cross(dFdy(VERTEX), dFdx(VERTEX)));
}
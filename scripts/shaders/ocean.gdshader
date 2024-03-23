shader_type spatial;

uniform float beers_law = 2.0;
uniform float noise_scale = 10.0;
uniform float height_scale = 0.15;
uniform float depth_offset = -0.75;
uniform float edge_scale = 0.1;
uniform float near = 1.0;
uniform float far = 1000.0;
uniform float metallic : hint_range(0.0, 1.0) = 0;
uniform float roughness : hint_range(0.0, 1.0) = 0.02;
uniform float time_scale : hint_range(0.0, 0.2, 0.005) = 0.025;

uniform vec3 albedo : source_color;
uniform vec3 albedo_2nd: source_color;
uniform vec3 edge_color: source_color;

uniform sampler2D wave;
uniform sampler2D texture_normal;
uniform sampler2D texture_normal_2nd;
uniform sampler2D mask_texture : hint_default_black;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform sampler2D depth_map : hint_default_black;
uniform float threshold : hint_range(0.0, 1.0);

varying float height;
varying float vertex_y;
varying vec2 screen_uv;
varying vec3 world_position;

float edge(float depth) {
	depth = 2.0 * depth - 1.0;
	return near * far / (far + depth * (near - far));
}

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.5 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

void vertex() {
	// Calculate screen space position
	vec4 screen_position = PROJECTION_MATRIX * (VIEW_MATRIX * (MODEL_MATRIX * vec4(VERTEX, 1.0)));
	
	// Pass screen space position to the fragment shader
    screen_uv = screen_position.xy / screen_position.w;
	
	vertex_y = VERTEX.y;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	height = texture(wave, world_position.xz / noise_scale + TIME * time_scale).r;
	
	VERTEX.y += height * height_scale;
}

void fragment() {
		//Getting edge depth calculations
	float z_depth = edge(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	float z_pos = edge(FRAGCOORD.z);
	float z_dif = z_depth - z_pos;
	
	//Depth variables and calculations
	float depth_texture = texture(DEPTH_TEXTURE, SCREEN_UV).r * 2.0 - 1.0;
	float depth = PROJECTION_MATRIX[3][2] / (depth_texture + PROJECTION_MATRIX[2][2]);
	float depth_blend = exp((depth + VERTEX.z * depth_offset) * beers_law);
	depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
	float depth_blend_pow = clamp(pow(depth_blend, 2.5), 0.0, 1.0);
	
	float fresnel = fresnel(5.0, NORMAL, VIEW);
	vec3 surface_color = mix(albedo, albedo_2nd, fresnel);
	vec3 normal_blend = mix(texture(texture_normal, UV).rgb, texture(texture_normal_2nd, UV).rgb, 0.5);
	
	vec3 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, depth_blend_pow * 2.5).rgb;
	vec3 depth_color = mix(albedo.rgb, albedo_2nd.rgb, depth_blend_pow);
	vec3 color = mix(screen_color * depth_color, depth_color * 0.25, depth_blend_pow * 0.5);
	
	vec3 depth_color_adj = mix(edge_color, color, step(edge_scale, z_dif));
	
	ALBEDO = clamp(surface_color + depth_color_adj, vec3(0.0), vec3(1.0));
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal_blend;
	
	ALPHA = 0.45;
	NORMAL = -normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
}

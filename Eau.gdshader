shader_type spatial;
render_mode blend_mix, specular_schlick_ggx;

uniform float speed : hint_range(-1,1) = 0.0;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D noise1;
uniform sampler2D noise2;
uniform sampler2D normalmap : hint_normal;

uniform vec4 color : source_color;
uniform vec4 ecumecolor : source_color;

uniform float edge_scale = 0.25;
uniform float near = 0.1;
uniform float far = 100.0;

//waves
uniform vec2 wave_strengh = vec2(0.5, 0.25);
uniform vec2 wave_frequency = vec2(12.0, 12.0);
uniform vec2 time_factor = vec2(1.0, 2.0);


float ecume(float depth){
	depth = 2.0 * depth - 1.0;
	return near * far / (far + depth * (near - far));
}

float waves(vec2 pos, float time){
	return (wave_strengh.y * sin(pos.y * wave_frequency.y + time * time_factor.y)) + (wave_strengh.x * sin(pos.x * wave_frequency.x + time * time_factor.x));
}

void vertex(){
	VERTEX.y += waves(VERTEX.xy, TIME);
}

void fragment(){
	
	float time = TIME * speed;
	
	vec3 n1 = texture(noise1, UV + time).rgb;
	vec3 n2 = texture(noise2, UV - time*0.2).rgb;
	
	vec2 uv_movement = UV * 4.0;
	uv_movement += TIME * speed * 4.0;
	
	
	float sum = (n1.r + n2.r) - 1.0;
	
	
	float z_depth = ecume(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	float z_pos = ecume(FRAGCOORD.z);
	float diff = z_depth - z_pos;
	
	vec2 displacement = vec2(sum * 0.05);
	diff += displacement.x * 20.0;
	
	vec4 col =  mix(ecumecolor, color, step(edge_scale, diff));
	
	vec4 alpha = texture(SCREEN_TEXTURE, SCREEN_UV + displacement);
	
	
	
	ALBEDO =mix(alpha.rgb, col.rgb, color.a);
	NORMAL_MAP = texture(normalmap, uv_movement).rgb;
	SPECULAR = 1.0;
	ROUGHNESS = 0.3;
}
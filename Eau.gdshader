shader_type spatial; //Type du shader, c'est un shader spatial puisqu'il est pris en compte dans l'espace 3D
render_mode blend_mix, specular_schlick_ggx; //mode de renu (se renseigné precisement sur chaque mode)

uniform float speed : hint_range(-1,1) = 0.0; //Mise en place de la variable modifiable vitesse des vagues

//Mise en place des texture 2D modifiables sur le shader (noise, normalmap etc..)
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D noise1;
uniform sampler2D noise2;
uniform sampler2D normalmap : hint_normal;

//Mise en place des variables modifiables des couleurs de l'eau et de l'écume
uniform vec4 color : source_color;
uniform vec4 ecumecolor : source_color;

//Mise en place des variables modifiables de la taille de l'écume, de comment elle s'étend sur l'eau etc..
uniform float edge_scale = 0.25;
uniform float near = 0.1;
uniform float far = 100.0;

//Mise en place des variables modifiables de la taille des vagues et de leur fréquence
uniform vec2 wave_strengh = vec2(0.5, 0.25);
uniform vec2 wave_frequency = vec2(12.0, 12.0);
uniform vec2 time_factor = vec2(1.0, 2.0);

//Code du fonctionnement de l'écume
float ecume(float depth){
	depth = 2.0 * depth - 1.0;
	return near * far / (far + depth * (near - far)); //calcul pour donner cette effet de remoue
}

//Code fonctionnement des vagues
float waves(vec2 pos, float time){
	return (wave_strengh.y * sin(pos.y * wave_frequency.y + time * time_factor.y)) + (wave_strengh.x * sin(pos.x * wave_frequency.x + time * time_factor.x));
}

//Code permettant d'activé les vagues sur le shader 
void vertex(){
	VERTEX.y += waves(VERTEX.xy, TIME); //modification concrètes du shader sur les axes x et y en fonction du temps
}


void fragment(){
	
	float time = TIME * speed; //application du changement de la vitesse de l'eau
	 
	//application de cette vitesse sur les textures noises
	vec3 n1 = texture(noise1, UV + time).rgb;
	vec3 n2 = texture(noise2, UV - time*0.2).rgb;
	
	//Le mouvement de l'eau qui ressort, servant plus tard à la normal map 
	vec2 uv_movement = UV * 4.0;
	uv_movement += TIME * speed * 4.0;
	
	//application de l'écume sur le shader 
	float sum = (n1.r + n2.r) - 1.0;// le -1.0 représente la distance de l'écume sur les textures (modifié directement "far" sur le shader c'est pareil)
	
	//Code pour faire les effets de remoue dans l'eau à la Breath of the wild 
	//float fin = 0.0;
	//if (sum > 0.0 && sum < 0.4) fin = 0.1;
	//if (sum > 0.4 && sum < 0.8) fin = 0.0;
	//if (sum > 0.8) fin = 1.0;

	//Application de l'écume sur shader en fonction de se qui entre en collision avec le shader
	float z_depth = ecume(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	float z_pos = ecume(FRAGCOORD.z);
	float diff = z_depth - z_pos;
	
	// Le déplacement de l'écume
	vec2 displacement = vec2(sum * 0.05);
	diff += displacement.x * 30.0; //plus la dernière valeur augmente plus l'écume sera mouvementé et présente sur l'eau
	
	//
	vec4 col =  mix(ecumecolor, color, step(edge_scale, diff));
	
	vec4 alpha = texture(SCREEN_TEXTURE, SCREEN_UV + displacement);
	
	
	
	ALBEDO = mix(alpha.rgb, col.rgb, color.a); //Application des couleurs sur le shader *(rajouter vec3(fin) +* au début pour ajouter l'effet de remoue dans l'eau
	NORMAL_MAP = texture(normalmap, uv_movement).rgb;
	SPECULAR = 1.0;
	ROUGHNESS = 0.3;
}
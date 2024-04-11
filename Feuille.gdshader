shader_type spatial; //Type du shader, c'est un shader spatial puisqu'il est pris en compte dans l'espace 3D
render_mode blend_mix, depth_draw_opaque,cull_disabled; //mode de renu (se renseigné precisement sur chaque mode)

//Création des variables modifiable 
//La texture utilisé, la couleur et la netteté de la texture
uniform sampler2D alphaTexture;
uniform vec4 leavesColor : source_color;
uniform float alphaThreshold = 0.1;

uniform float offsetScale : hint_range(0.001, 1.0, 0.001);

//Les reflets de couleur 
uniform float fresnelStrength : hint_range(-2.0, 2.0) =  0.5;
uniform float fresnelBlend : hint_range(-1.0,1.0) = 1.0;
uniform vec4 fresnelColor : source_color = vec4(0.58,0.65,0.33,1.0);

//Appelation des shaders globeaux créés dans project setting -> shader global 
global uniform float WindScale;
global uniform float WindSpeed;
global uniform float WindStrength;
global uniform float WindDensity;
uniform bool deactiveGlobalVariation;

//Variable modifiable permettant de modifier comment agis le vent etc..
uniform float clampTop : hint_range(0.0,1.0) = 1.0;
uniform float clampBottom : hint_range(-1.0, 0.0) = 0.0;


//Fonction obligatoire dans les shaders 
void fragment() {
	
	//Code de l'effet des reflets de couleurs sur les feuilles
	float rate_col = clamp(COLOR.r,0.0,1.0);
	float fresnel = pow(1.0 - clamp(dot(NORMAL,VIEW),0.0,1.0),3.0); //Gérer l'effet de flou du reflet (Plus le dernier chiffre augmente plus les reflets ressembleronts à des outlines)
	float fresnel_rate = clamp(rate_col,0.1,1);
	
	vec3 albedo = vec3(leavesColor.xyz); //Là on applique la couleurs modifié mais seulement pour l'effet de reflet
	vec3 fres_col = albedo * (1.0-fresnelStrength); //Effet de lumières en fonction de la couleurs
	fres_col += fresnelColor.rgb * fresnelStrength;
	fres_col *= fresnel;
	fres_col *= fresnel_rate;
	fres_col *= fresnelBlend;
	
	//Appliquation de toutes les variables modifiables sur notre shader
	ALBEDO = vec3(leavesColor.xyz);
	ALPHA = texture(alphaTexture,UV).x;
	ALPHA_SCISSOR_THRESHOLD = alphaThreshold;
	EMISSION = fres_col;
}

void vertex(){
	
	//Placement du shader 
	vec2 uvOffset = vec2(UV.x * 2.0 - 1.0, -(UV.y * 2.0 - 1.0)); //Répétition du shader sur axe x et y 
	uvOffset /= 2.0; //Le scale globale de l'image autour du mesh pour le shader 
	vec4 off = inverse(MODELVIEW_MATRIX) * vec4(uvOffset,0.5,0.0);
	off = vec4(normalize(off.xyz),0.0) * offsetScale;
	
	//Tout l'effet du vent (je t'avoue que je comprend pas tout sur cette partie là lol) 
	vec3 world_pos = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	float contribution = 8.0 * (1.0 - float(deactiveGlobalVariation));
	vec3 world_pos_eff = world_pos * contribution;
	float positional_influence = - VERTEX.x + VERTEX.z - world_pos_eff.x + world_pos_eff.z;
	float offset = fract(positional_influence * (1.0/WindScale) + (TIME * WindScale/1000.0));
	offset = min(2.0 - offset, offset);
	offset = (1.0 - offset) * offset * 2.0;
	
	float t = TIME + sin(TIME + offset + cos(TIME + offset * WindStrength * 2.0) * WindStrength);
	float mask = clamp(VERTEX.y * WindDensity,0.0, 1.0) * (clampTop - clampBottom) + clampBottom;
	
	float si = sin(t) / 20.0 * WindStrength * offset;
	float csi = cos(t) / 20.0 * WindStrength * offset;
	
	vec3 wind_offset = vec3(VERTEX.x * si * mask, VERTEX.y * si * mask, VERTEX.z * csi * mask);
	
	VERTEX += off.xyz + wind_offset;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}

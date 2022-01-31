#define PI 3.14

// User defined
uniform mediump vec4 falloff;
uniform lowp vec4 color;
uniform lowp vec4 ambient_light;
uniform mediump vec4 angle;
uniform mediump vec4 penetration;
uniform mediump vec4 size;

uniform lowp sampler2D texture_sampler;

varying mediump vec2 var_texcoord0;

// Sample from the 1D distance map
float sample_from_distance_map(vec2 coord, float r) {
	return step(r, texture2D(texture_sampler, coord).r);
}

void main(void) {
	float theta = atan(var_texcoord0.y, var_texcoord0.x);
	
	// Discard if not inside angle
	if (theta > angle.y || theta < angle.w || (theta > 0.0 && theta < angle.x) || (theta < 0.0 && theta > angle.z)) 
		discard;
	
	// Rectangular to polar
	// r = 0.0 on top of light
	// r = 1.0 as far away from the light as possible
	float r = length(var_texcoord0);

	// The tex coord to sample our 1D lookup texture
	float coord = (theta + PI) / (2.0 * PI);
	vec2 tc = vec2(coord, 0.0);
	float visible = sample_from_distance_map(tc, r);

	float light_radius = (size.x / falloff.x) / size.x;
	float inside_light = 1.0 - step(light_radius, r);
	float outside_light = 1.0 - inside_light;
	//visible = visible * inside_light;

	vec4 composed_color = vec4(0);
	composed_color.r = mix(color.r, 0, r * falloff.x) * visible * inside_light;
	composed_color.g = mix(color.g, 0, r * falloff.x) * visible * inside_light;
	composed_color.b = mix(color.b, 0, r * falloff.x) * visible * inside_light;
	composed_color.a = 1.0 * r * falloff.x;
	gl_FragColor = composed_color;
}
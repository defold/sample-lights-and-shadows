#define PI 3.14

// User defined
uniform mediump vec4 property;
uniform lowp vec4 color;
uniform mediump vec4 angle;

uniform lowp sampler2D texture_sampler;

varying mediump vec2 var_texcoord0;

// Sample from the 1D distance map
float sample(vec2 coord, float r) {
	return step(r, texture2D(texture_sampler, coord).r);
}

void main(void) {
	// Rectangular to polar
	float theta = atan(var_texcoord0.y, var_texcoord0.x);
	
	// Discard if not inside angle
	if (theta > angle.y || theta < angle.w || (theta > 0 && theta < angle.x) || (theta < 0 && theta > angle.z)) 
		discard;
	
	// Rectangular to polar
	float r = length(var_texcoord0);	
	float coord = (theta + PI) / (2.0 * PI);

	// The tex coord to sample our 1D lookup texture	
	vec2 tc = vec2(coord, 0.0);    

	// Multiply the summed amount by our distance, which gives us a radial falloff
	// Then multiply by vertex (light) color  
	gl_FragColor = color * vec4(sample(tc, r) * smoothstep(1.0, 0.0, r * property.x));
}
#define PI 3.14

varying mediump vec2 var_texcoord0;
varying mediump vec2 var_coord;

uniform lowp sampler2D texture_sampler;

// User defined
uniform mediump vec4 resolution;

// Alpha threshold for occlusion map
const mediump float THRESHOLD = 0.75;

void main()
{
	lowp float distance = 1.0;

	lowp float inverseRes = 1.0 / resolution.y;
	// Calculate this in vertex
	// float theta = PI * 1.5 + (var_texcoord0.s * 2.0 - 1.0) * PI; 
	lowp float theta = var_texcoord0.x; 

	// Coord which we will sample from occlude map
	vec2 coord = vec2(-inverseRes * sin(theta), inverseRes * cos(theta));
	vec2 step = coord;
	float resy = resolution.y;
	for (float y = 1.0; y < 50000.0; y += 1.0) {
		// webgl doesn't allow for-loops with non constant end value
		// we use this as a workaround
		if (y > resolution.y) break;
		
		//sample the occlusion map
		lowp float data = texture2D(texture_sampler, coord / 2.0 + 0.5).a;
		
		// If we've hit an opaque fragment (occluder), then get new distance
		// If the new distance is below the current, then we'll use that for our ray
		if (data > THRESHOLD) {
			distance = y / resolution.y;
			break;
		}
		coord += step;
	} 

	gl_FragColor = vec4(vec3(distance), 1.0);
}

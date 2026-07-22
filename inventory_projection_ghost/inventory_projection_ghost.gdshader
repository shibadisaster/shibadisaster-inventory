shader_type canvas_item;


uniform sampler2D noise_tex: repeat_enable;
uniform sampler2D valid_gradient;
uniform sampler2D invalid_gradient;
uniform bool valid;
uniform float fading: hint_range(0.0, 1.0, 0.01);


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float noise_val = textureLod(noise_tex, UV + vec2(1.0, 1.0) * TIME, 0.0).r;
	
	if (noise_val < fading) discard;
	
	vec4 color;
	if (valid) { color = textureLod(valid_gradient, vec2(noise_val, 0.5), 0.0); }
	else { color = textureLod(invalid_gradient, vec2(noise_val, 0.5), 0.0); }
	float original_alpha = COLOR.a;
	color.a = original_alpha;
	
	COLOR = color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}

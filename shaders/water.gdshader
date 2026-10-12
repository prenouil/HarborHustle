// Eau du port : bleu profond, vaguelettes et reflets lumineux qui ondulent.
shader_type spatial;

uniform vec4 deep_color : source_color = vec4(0.04, 0.2, 0.52, 1.0);
uniform vec4 light_color : source_color = vec4(0.25, 0.55, 0.9, 1.0);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(world_pos.x * 0.15 + TIME) * 0.06 + cos(world_pos.z * 0.2 + TIME * 0.8) * 0.06;
}

void fragment() {
	vec2 p = world_pos.xz;
	float a = sin(p.x * 0.35 + sin(p.y * 0.27 + TIME * 0.6) * 1.6 + TIME * 0.4);
	float b = sin(p.y * 0.31 + sin(p.x * 0.22 - TIME * 0.5) * 1.4 - TIME * 0.3);
	float glints = smoothstep(0.9, 0.99, abs(a * b));
	float swell = 0.5 + 0.5 * sin(p.x * 0.05 + p.y * 0.07 + TIME * 0.2);
	ALBEDO = mix(deep_color.rgb, light_color.rgb, 0.15 + 0.15 * swell + 0.45 * glints);
	ROUGHNESS = 0.35;
	SPECULAR = 0.3;
}

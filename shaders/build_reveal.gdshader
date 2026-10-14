// Bâtiment en construction : seule la partie sous reveal_y est visible,
// avec une lisière lumineuse là où il « pousse ».
shader_type spatial;
render_mode cull_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;
uniform float reveal_y = 0.0;
uniform vec4 edge_color : source_color = vec4(0.44, 0.83, 1.0, 1.0);

varying float world_y;

void vertex() {
	world_y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	if (world_y > reveal_y) {
		discard;
	}
	ALBEDO = albedo.rgb;
	ROUGHNESS = 0.85;
	float edge = 1.0 - smoothstep(0.0, 0.4, reveal_y - world_y);
	EMISSION = emission_color.rgb * emission_energy + edge_color.rgb * edge * 2.5;
}

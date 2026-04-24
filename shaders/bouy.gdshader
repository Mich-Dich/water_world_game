shader_type spatial;

uniform sampler2D scatch_texture : repeat_enable;
uniform vec4 color : source_color = vec4(1.0, 0.5, 0.0, 1.0);

void fragment() {
	vec4 scratch = texture(scatch_texture, UV);
	ALBEDO = mix(color.rgb, scratch.rgb, scratch.b);
	ROUGHNESS = scratch.r;
}

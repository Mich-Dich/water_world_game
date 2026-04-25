shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// height settings
uniform sampler2D heightmap_large : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D heightmap_small : source_color, filter_linear_mipmap, repeat_enable;
uniform float scale_large		= 0.001;
uniform float scale_small		= 0.1;
uniform float amplitude_large	= 20.0;
uniform float amplitude_small	= 1.0;

// color settings
uniform sampler2D color_noise : source_color, filter_linear_mipmap, repeat_enable;
uniform float color_noise_scale = 0.05;
uniform float blend_sharpness = 0.0;
uniform vec4 grass_color : source_color = vec4(0.15, 0.55, 0.2, 1.0);
uniform vec4 sand_color : source_color = vec4(0.85, 0.8, 0.6, 1.0);
varying vec2 frag_world_xz;

// normal recalc
uniform float normal_sample_offset = 0.5;


float sample_height(vec2 ws_xz) {
	float h_large = texture(heightmap_large, ws_xz * scale_large).r;
	float h_small = texture(heightmap_small, ws_xz * scale_small).r;
	return (h_large * amplitude_large) + (h_small * amplitude_small);
}


void vertex() {
	vec4 world_pos = MODEL_MATRIX * vec4(VERTEX, 1.0);
	vec2 world_xz = world_pos.xz;
	
	VERTEX.y += sample_height(world_xz);
	frag_world_xz = world_xz;
}


void fragment() {
	float noise_val = texture(color_noise, frag_world_xz * color_noise_scale).r;
	float t = smoothstep(0.5 - blend_sharpness, 0.5 + blend_sharpness, noise_val);
	ALBEDO = mix(sand_color.rgb, grass_color.rgb, t);
}

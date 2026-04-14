shader_type spatial;
render_mode blend_mix, unshaded;

// Grid appearance
uniform vec4 color_bg : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 color_line : source_color = vec4(0.3, 0.3, 0.3, 1.0);
uniform float grid_size : hint_range(0.1, 10.0) = 1.0;
uniform float line_width_screen : hint_range(0.5, 5.0) = 1.5; // width in pixels

void fragment() {
	// Get world position
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Compute derivatives (how fast UV changes in screen space)
	vec2 dx = dFdx(world_pos.xz);
	vec2 dy = dFdy(world_pos.xz);
	
	// Distance to nearest grid line in world units, then convert to screen‑space width
	vec2 dist_to_line;
	dist_to_line.x = min(mod(world_pos.x, grid_size), grid_size - mod(world_pos.x, grid_size));
	dist_to_line.y = min(mod(world_pos.z, grid_size), grid_size - mod(world_pos.z, grid_size));
	
	// Estimate screen‑space width of the line (how many pixels we are from the line center)
	vec2 screen_width = fwidth(dist_to_line);
	vec2 line_alpha = 1.0 - smoothstep(0.0, line_width_screen * 0.5, dist_to_line / screen_width);
	float is_line = max(line_alpha.x, line_alpha.y);
	
	// ----- Major lines (every 10 units) -----
	const float major_step = 10.0;
	vec2 dist_to_major;
	dist_to_major.x = min(mod(world_pos.x, major_step), major_step - mod(world_pos.x, major_step));
	dist_to_major.y = min(mod(world_pos.z, major_step), major_step - mod(world_pos.z, major_step));
	
	vec2 major_width = fwidth(dist_to_major);
	vec2 major_alpha = 1.0 - smoothstep(0.0, line_width_screen * 0.5, dist_to_major / major_width);
	float is_major_x = major_alpha.x;
	float is_major_z = major_alpha.y;
	
	// Determine major line color
	vec4 major_color = color_line;
	if (is_major_x > 0.0 && is_major_z > 0.0) {
		major_color = vec4(1.0, 1.0, 0.0, 1.0); // yellow
	} else if (is_major_x > 0.0) {
		major_color = vec4(1.0, 0.0, 0.0, 1.0); // red
	} else if (is_major_z > 0.0) {
		major_color = vec4(0.0, 1.0, 0.0, 1.0); // green
	}
	
	// Combine: background -> black lines -> major lines (overwrite)
	vec4 final_color = color_bg;
	final_color = mix(final_color, color_line, is_line);
	float major_factor = max(is_major_x, is_major_z);
	final_color = mix(final_color, major_color, major_factor);
	
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
}
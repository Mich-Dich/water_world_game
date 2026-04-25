shader_type spatial;

uniform sampler2D color : source_color, filter_linear_mipmap, repeat_enable;


void fragment() {
	ALBEDO = texture(color, UV).rgb;
}

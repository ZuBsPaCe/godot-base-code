shader_type canvas_item;
render_mode unshaded;

uniform sampler2D flat_light_tex;
uniform float flat_light_factor = 0.5;

void fragment() {
	vec4 screen_col = texture(TEXTURE, UV);
	vec4 light_col = texture(flat_light_tex, UV);
	
	COLOR = vec4(mix(screen_col.rgb, light_col.rgb, flat_light_factor), 1.0);
}


shader_type canvas_item;
render_mode unshaded;

uniform sampler2D flat_light_tex;

void fragment() {
	//vec4 obj_col = texture(TEXTURE, UV);
	vec4 light_col = texture(flat_light_tex, SCREEN_UV);
	
	//COLOR = vec4(obj_col.rgb * light_col.rgb, obj_col.a);
	COLOR = COLOR * light_col;
}


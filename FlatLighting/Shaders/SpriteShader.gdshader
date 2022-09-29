shader_type canvas_item;
render_mode unshaded;

// The flat_light texture. 1 is fully lit. 0 is fully shadowed.
uniform sampler2D flat_light_tex;

float luminance(vec3 p_col)
{
	return p_col.r * 0.3 + p_col.g * 0.59 + p_col.b * 0.11;
}


void fragment() {
	
	// Sample flatlight texture with optional offset.
	vec2 light_uv = SCREEN_UV;
	
	// Light amount
	vec4 light_col_4 = texture(flat_light_tex, light_uv);
	
	float light_lum = luminance(light_col_4.rgb);
	
	// Sample object / tile texture
	vec4 obj_col4 = texture(TEXTURE, UV);
	
	vec3 final_col = light_col_4.rgb * obj_col4.rgb;
	
	// THATS IT:
	COLOR = vec4(final_col, light_lum * obj_col4.a);
	//COLOR = obj_col4;
}

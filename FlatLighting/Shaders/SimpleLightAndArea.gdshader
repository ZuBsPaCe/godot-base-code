shader_type canvas_item;
render_mode unshaded;

uniform sampler2D light_tex;
uniform sampler2D area_tex;

//void fragment() {
//	//vec4 obj_col = texture(TEXTURE, UV);
//	vec4 light_col = texture(light_tex, SCREEN_UV);
//	vec4 area_col = texture(area_tex, SCREEN_UV);
//
//	vec4 source_col = COLOR;
//
//	float light_factor = (light_col.r * 0.2125) + (light_col.g * 0.7154) + (light_col.b * 0.0721);
//
//	float source_lightness = (source_col.r * 0.2125) + (source_col.g * 0.7154) + (source_col.b * 0.0721);
//	float area_lightness = (area_col.r * 0.2125) + (area_col.g * 0.7154) + (area_col.b * 0.0721);
//
//	source_lightness *= 0.25;
//
//	vec4 source_gray_col = vec4(source_lightness, source_lightness, source_lightness, area_lightness);
//
//	COLOR = mix(source_gray_col, source_col * light_col, light_factor);
//}

void fragment() {
	vec4 light_col = texture(light_tex, SCREEN_UV);
	vec4 area_col = texture(area_tex, SCREEN_UV);
	
	float colored_factor = (area_col.r * 0.2125) + (area_col.g * 0.7154) + (area_col.b * 0.0721);
	
	vec4 source_col = COLOR;
	
	vec4 shaded_col = source_col * light_col;
	
	vec4 adjusted_col = source_col * (0.25 + light_col);
	float shaded_lightness = (adjusted_col.r * 0.2125) + (adjusted_col.g * 0.7154) + (adjusted_col.b * 0.0721);
	vec4 shaded_gray = vec4(shaded_lightness, shaded_lightness, shaded_lightness, shaded_col.a);

	COLOR = mix(shaded_gray, shaded_col, colored_factor);
}


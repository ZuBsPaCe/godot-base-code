shader_type canvas_item;
render_mode unshaded;

uniform sampler2D flat_light_tex;


//uniform float radius = 5.0;
uniform float shadow_alpha = 0.5;
//
//vec4 blur(sampler2D t, vec2 uv, vec2 pixel_size) {
//	vec4 new_color = texture(t, uv);
//
//	new_color += texture(t, uv + vec2(0, -radius) * pixel_size);
//	new_color += texture(t, uv + vec2(0, radius) * pixel_size);
//	new_color += texture(t, uv + vec2(-radius, 0) * pixel_size);
//	new_color += texture(t, uv + vec2(radius, 0) * pixel_size);
//
//	return new_color / 5.0;
//}

void fragment() {
	vec4 screen_col = texture(TEXTURE, UV);
	vec4 light_col = texture(flat_light_tex, UV);
	
	//light_col = textureLod(flat_light_tex, UV, 10.0);
	
//	vec4 light_col = blur(flat_light_tex, UV, TEXTURE_PIXEL_SIZE);
	
	
	COLOR = vec4(screen_col.rgb * mix(shadow_alpha, 1.0, light_col.r), 1.0);
	//COLOR = light_col;
	//COLOR = mix(screen_col, light_col, 0.5);
	
}


shader_type canvas_item;
render_mode unshaded, blend_add;

uniform sampler2D light_tex;
uniform vec4 color : hint_color = vec4(1.0);

uniform sampler2D noise_tex;
uniform float noise_offset;

void fragment() {
//	vec4 light = texture(TEXTURE, UV);
//	vec4 shadow = texture(shadowtex, UV);
//
//	COLOR = vec4(light.r, light.g - shadow.r, light.b - shadow.r, 1.0);
	//COLOR = shadow;
	//COLOR = light;
	//COLOR = 0.5 * (light + shadow);
	
	vec4 shadow = texture(TEXTURE, UV);
	
	
	vec4 light = texture(light_tex, UV) * color;
	
	//vec2 uv = (UV - vec2(0.5)) * ((sin(TIME * 10.0) + 11.0) * 0.1) + vec2(0.5);
//	vec2 uv = (UV - vec2(0.5)) * (1.0 + texture(noise_tex, vec2(fract((TIME + noise_offset) * 0.1), noise_offset)).r) + vec2(0.5);
//	vec4 light = texture(light_tex, uv) * color;
	
	//COLOR = vec4(light.r, light.g - shadow.r, light.b - shadow.r, 1.0);
//	COLOR = vec4(max(0.1, light.r - shadow.r), light.g - shadow.r, light.b - shadow.r, 1.0);

	COLOR = vec4(light.r - shadow.r, light.g - shadow.r, light.b - shadow.r, 1.0);
}

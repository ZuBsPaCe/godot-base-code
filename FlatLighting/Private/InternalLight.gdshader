shader_type canvas_item;
render_mode unshaded, blend_add;

uniform sampler2D light_tex;
uniform vec4 color : source_color = vec4(1.0);

uniform float radius = 0.5;
uniform float transition = 0.5;

float circle(vec2 p_uv, vec2 p_pos, float p_radius, float p_transition)
{
    vec2 dist = p_uv - p_pos;
    return 1.0 - smoothstep(p_radius - 2.0 * p_transition, p_radius, length(dist));
}

void fragment() {
	vec4 shadow = texture(TEXTURE, UV);
//	vec2 light2 = texture(light_tex, UV).rg * color.rg;
//
//	COLOR = vec4(light2.rg * (1.0 - shadow.r), shadow.r, 1.0);

//	float light = sin(UV.x * PI) * cos(UV.y * PI);

 	//float light = smoothstep(0.0, 1.0, 1.0 - distance(UV, vec2(0.5)) * 2.0);
	float light = circle(UV, vec2(0.5), radius, radius * transition);
	light *= 1.0 - shadow.r;
	vec3 col = color.rgb * light;
	COLOR = vec4(col, 1.0);
}

shader_type canvas_item;
render_mode unshaded;

uniform bool cycle_enabled = false;
uniform vec4 selected_col_linear : source_color;



// https://gist.github.com/mairod/a75e7b44f68110e1576d77419d608786#gistcomment-3195243
vec3 hue_shift(vec3 color, float hue) {
    const vec3 k = vec3(0.57735, 0.57735, 0.57735);
    float cosAngle = cos(hue);
    return vec3(color * cosAngle + cross(k, color) * sin(hue) + k * dot(k, color) * (1.0 - cosAngle));
}

vec4 to_linear(vec4 col) {
		return vec4(
				col.r < 0.04045 ? col.r * (1.0 / 12.92) : pow((col.r + 0.055) * (1.0 / (1.0 + 0.055)), 2.4),
				col.g < 0.04045 ? col.g * (1.0 / 12.92) : pow((col.g + 0.055) * (1.0 / (1.0 + 0.055)), 2.4),
				col.b < 0.04045 ? col.b * (1.0 / 12.92) : pow((col.b + 0.055) * (1.0 / (1.0 + 0.055)), 2.4),
				col.a);
}

vec4 to_srgb(vec4 col)  {
		return vec4(
				col.r < 0.0031308 ? 12.92 * col.r : (1.0 + 0.055) * pow(col.r, 1.0f / 2.4f) - 0.055,
				col.g < 0.0031308 ? 12.92 * col.g : (1.0 + 0.055) * pow(col.g, 1.0f / 2.4f) - 0.055,
				col.b < 0.0031308 ? 12.92 * col.b : (1.0 + 0.055) * pow(col.b, 1.0f / 2.4f) - 0.055, 
				col.a);
}

bool is_srgb_equal(vec4 col1, vec4 col2) {
	const float diff = 1.0 / 256.0 * 0.5;
	
	return abs(col1.r - col2.r) <= diff;// && abs(col1.g - col2.g) <= diff && abs(col1.b - col2.b) <= diff;// && col1.a == col2.a;
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	
	vec4 selected_col = to_srgb(selected_col_linear);
	
	if (is_srgb_equal(col, selected_col)) {
		if (cycle_enabled) {
			float factor = (UV.x + UV.y + TIME * 8.0) / 2.0;
			factor = sin(factor);
			factor = (factor + 1.0) / 2.0;
			
			vec3 other_col = vec3(1.0, 0.0, 1.0);
			other_col = hue_shift(other_col, factor * 2.0 * PI);
			
			col = mix(col, vec4(other_col, 1.0), factor);
		} else {
			float shift = sin(TIME * 4.0);
			if (col.r >= 0.5 || col.g >= 0.5 || col.b >= 0.5) {
				col.rgb += (shift * 0.1);
			} else {
				col.rgb -= (shift * 0.1);
			}
		}
	} else {
		col.rgb *= 0.25;
	}
	
	COLOR = col;
}

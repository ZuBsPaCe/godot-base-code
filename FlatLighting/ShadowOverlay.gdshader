shader_type canvas_item;

render_mode blend_mix, unshaded;


void fragment(){
	//COLOR = texture(TEXTURE, UV);
	float alpha = texture(TEXTURE, UV).r;
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
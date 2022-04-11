shader_type spatial;
render_mode skip_vertex_transform, unshaded, depth_draw_never, depth_test_disabled, blend_add, cull_disabled;

// We need uv2 which is only possible in spatial shaders.
// https://github.com/godotengine/godot/issues/9134#issuecomment-320544933

// About Viewport "V Flip": See Viewport.get_texture() documentation
// Note: Due to the way OpenGL works, the resulting ViewportTexture is flipped 
// vertically. You can use Image.flip_y() on the result of Texture.get_data() 
// to flip it back.


// See first version:
// https://github.com/slembcke/CausticCavern.spritebuilder/blob/softshadows/SoftShadow.fsh
// https://github.com/slembcke/CausticCavern.spritebuilder/blob/softshadows/SoftShadow.vsh

uniform vec2 light_pos_array[8];
uniform float light_radius_array[8];

varying vec4 positionFrag;
varying vec4 clipFrag;
varying vec2 segment;
varying vec2 segmentAFrag;
varying vec2 segmentBFrag;
varying mat2 edgeAFrag;
varying mat2 edgeBFrag;

varying vec2 segCoords;


mat2 edgeMatrix(vec2 d, float r){
	float a = 1.0/dot(d, d);
	float b = 1.0/(r*length(d) + 1e-15);
	return mat2(vec2(a*d.x, -b*d.y), vec2(a*d.y, b*d.x));
}

void vertex(){
	// Unpack the vertex data.
	// INV_VIEW_MATRIX = CAMERA_MATRIX
	vec3 cam_pos = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	int index = int(cam_pos.z) - 1;
	
	vec2 light_pos = light_pos_array[index];
	float light_radius = light_radius_array[index];
	
	vec2 lightPosition = light_pos;
	vec2 segmentA = UV2;
	vec2 segmentB = UV;
	vec2 segmentCoords = VERTEX.xy;
	float projectionOffset = (VERTEX.x - 0.5) * 2.0;
	
	// Transform local vertex coords to world coords.
	segmentA = (MODEL_MATRIX * vec4(segmentA, 0.0, 1.0)).xy;
	segmentB = (MODEL_MATRIX * vec4(segmentB, 0.0, 1.0)).xy;
	
//	float distToSegmentA = length(lightPosition-segmentA);
//	segmentA -= normalize(lightPosition-segmentA) * clamp(distToSegmentA, 0.0, 64.0) / 64.0 * 32.0;
//
//	float distToSegmentB = length(lightPosition-segmentB);
//	segmentB -= normalize(lightPosition-segmentB) * clamp(distToSegmentB, 0.0, 64.0) / 64.0 * 32.0;


	vec2 segmentPosition = mix(segmentA, segmentB, segmentCoords.x);
	vec2 lightDirection = normalize(segmentPosition - lightPosition);

	// Calculate the point to project the shadow edge from the light's position/size.
	vec2 projectionPosition = lightPosition + projectionOffset * light_radius * vec2(lightDirection.y, -lightDirection.x);
	vec2 projectedPosition = segmentPosition - projectionPosition*segmentCoords.y;

	vec2 segmentTangent = normalize(segmentB - segmentA);
	vec2 segmentNormal = vec2(-segmentTangent.y, segmentTangent.x);

	vec4 projected = vec4(projectedPosition, 0.0, 1.0 - segmentCoords.y);

	float cam_x = INV_VIEW_MATRIX[3][0];
	float cam_y = INV_VIEW_MATRIX[3][1];

	POSITION = PROJECTION_MATRIX * vec4(
		projected.x - cam_x * projected.w,
		projected.y - cam_y * projected.w,
		projected.z - 2.0 * projected.w,
		projected.w);
	
	// Output fragment data!
	segment = segmentPosition;
	positionFrag = projected;
	clipFrag = vec4(segmentNormal, 0.0, dot(segmentNormal, segmentA + segmentB)*0.5);
	segmentAFrag = segmentA;
	segmentBFrag = segmentB;
	edgeAFrag = edgeMatrix(segmentA - lightPosition, light_radius);
	edgeBFrag = edgeMatrix(segmentB - lightPosition, light_radius);
	
	segCoords = segmentCoords;
}

float soften(float t){
	return t*(3.0 - t*t)*0.25 + 0.5;
}

float edgef(mat2 m, vec2 delta, float clipped){
	vec2 v = m*delta;
	return (v[0] > 0.0 ? soften(clamp(v[1]/v[0], -1.0, 1.0)) : clipped);
}

void fragment(){
	vec2 position = positionFrag.xy/positionFrag.w;
	
	if (dot(position, clipFrag.xy) > clipFrag.w) {
		discard;
	}

	float occlusionA = edgef(edgeAFrag, position - segmentAFrag, 1.0);
	float occlusionB = edgef(edgeBFrag, position - segmentBFrag, 0.0);
	
	float occlusion = occlusionA - occlusionB;

//	float inset = distance(position, segment);
//	float dist = distance(position, light_pos);
//	float reveal = 48.0 - 40.0 * clamp(dist / 800.0, 0.0, 1.0);
//
//	float inset_fac = clamp(inset / reveal, 0.0, 1.0);
//	float alphaFactor = inset_fac;


//	float lightDist = distance(position, light_pos);
//	float alphaFactor = clamp(lightDist / 800.0, 0.0, 1.0);
//	alphaFactor = alphaFactor * alphaFactor * alphaFactor;
	
//	float alphaFactor = clamp(inset / 40.0, 0.0, 1.0);
//	float alphaFactor = segCoords.y;
	float alphaFactor = 1.0;
	
	ALBEDO = vec3(occlusion, occlusion, occlusion) * alphaFactor;
	ALPHA = 1.0;
	
//	vec3 world_camera = (CAMERA_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
//	ALBEDO.x = 1.0 / (world_camera.z / 2.0) ;


//	vec3 world_camera = (CAMERA_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
//	ALBEDO.r *= (world_camera.z / 2.0);
}
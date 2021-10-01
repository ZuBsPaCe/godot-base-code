shader_type spatial;
//render_mode skip_vertex_transform, unshaded, depth_draw_never, depth_test_disable, blend_add;
//render_mode unshaded, depth_draw_never, depth_test_disable, blend_add, cull_disabled;

//render_mode skip_vertex_transform, unshaded, depth_draw_never, depth_test_disable, blend_add, cull_disabled;
render_mode skip_vertex_transform, unshaded, depth_draw_never, depth_test_disable, blend_add, cull_disabled;

// We need uv2 which is only possible in spatial shaders.
// https://github.com/godotengine/godot/issues/9134#issuecomment-320544933

// About Viewport "V Flip": See Viewport.get_texture() documentation
// Note: Due to the way OpenGL works, the resulting ViewportTexture is flipped 
// vertically. You can use Image.flip_y() on the result of Texture.get_data() 
// to flip it back.


// See first version:
// https://github.com/slembcke/CausticCavern.spritebuilder/blob/softshadows/SoftShadow.fsh
// https://github.com/slembcke/CausticCavern.spritebuilder/blob/softshadows/SoftShadow.vsh

uniform vec2 light_pos = vec2(0.0, 0.0);
uniform float light_radius = 50.0;

uniform float debug = 1.0;


varying vec4 positionFrag;
varying vec4 clipFrag;
varying vec2 segmentAFrag;
varying vec2 segmentBFrag;
varying mat2 edgeAFrag;
varying mat2 edgeBFrag;

varying float test;
varying vec2 from;
varying vec2 to;
varying vec4 proj;
varying vec2 segment;

mat2 edgeMatrix(vec2 d, float r){
	float a = 1.0/dot(d, d);
	float b = 1.0/(r*length(d) + 1e-15);
	return mat2(vec2(a*d.x, -b*d.y), vec2(a*d.y, b*d.x));
}

void vertex(){
	// Unpack the vertex data.
	vec2 lightPosition = light_pos;
	vec2 segmentA = UV2;
	vec2 segmentB = UV;
	vec2 segmentCoords = VERTEX.xy;
	float projectionOffset = (VERTEX.x - 0.5) * 2.0;
	float radius = light_radius * debug;

	vec2 segmentPosition = mix(segmentA, segmentB, segmentCoords.x);
	vec2 lightDirection = normalize(segmentPosition - lightPosition);

	// Calculate the point to project the shadow edge from the light's position/size.
	vec2 projectionPosition = lightPosition + projectionOffset*radius*vec2(lightDirection.y, -lightDirection.x);
	vec2 projectedPosition = segmentPosition - projectionPosition*segmentCoords.y;

	vec2 segmentTangent = normalize(segmentB - segmentA);
	vec2 segmentNormal = vec2(-segmentTangent.y, segmentTangent.x);

	vec4 projected = vec4(projectedPosition, 0.0, 1.0 - segmentCoords.y);
	
	float before = projected.w;
	
	// https://www.3dgep.com/understanding-the-view-matrix/
	// Hint: view_mat[3][2] == -1
	// view_mat == INV_CAMERA_MATRIX
	// No idea, why z-transform is -2, but it's the way it is.
	float cam_x = CAMERA_MATRIX[3][0];
	float cam_y = CAMERA_MATRIX[3][1];
	mat4 view_mat = mat4(vec4(1,0,0,0),vec4(0,1,0,0),vec4(0,0,1,0),vec4(-cam_x,-cam_y,-2,1));

	// UV & UV2 & LightPos is in global coords, but occluder can be shifted (occluder_mesh_instance.translation).
	// That's why we can't take MODELVIEW_MATRIX. INV_CAMERA_MATRIX ist just the view part.
	//POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * projected;
	//POSITION = PROJECTION_MATRIX * INV_CAMERA_MATRIX * projected;
	//POSITION = PROJECTION_MATRIX * view_mat * projected;
	POSITION = PROJECTION_MATRIX * vec4(
		projected.x - cam_x * projected.w,
		projected.y - cam_y * projected.w,
		projected.z - 2.0 * projected.w,
		projected.w);

	proj = projected;
	
	
//	vec2 reveal_point = segmentPosition + lightDirection * 32.0;
//	w_reveal = segmentPosition.x / reveal_point.x;
	
	segment = segmentPosition;
	
	
	// => w is equal, before and after!
//	float after =POSITION.w;
//	if (abs(before -after) > 0.00001){
//		test = 0.0;
//	}else{
//		test = 1.0;
//	}

	
//	if (INV_CAMERA_MATRIX == view_mat) {
//		test = 1.0;
//	} else {
//		test = 0.0;
//	}
	
	

	
	// Output fragment data!
	positionFrag = projected;
	clipFrag = vec4(segmentNormal, 0.0, dot(segmentNormal, segmentA + segmentB)*0.5);
	segmentAFrag = segmentA;
	segmentBFrag = segmentB;
	edgeAFrag = edgeMatrix(segmentA - lightPosition, radius);
	edgeBFrag = edgeMatrix(segmentB - lightPosition, radius);
	
	
//	from = PROJECTION_MATRIX * INV_CAMERA_MATRIX *  vec4(projectedPosition, 0.0, 1.0);
//	to = PROJECTION_MATRIX * INV_CAMERA_MATRIX *  vec4(projectedPosition, 0.0, 0.0);
from = projectedPosition;
to = projectedPosition;
	//test = segmentCoords.y;
	
	//test = dist(projected.xy, projected.xy/projected.w)
	
	
	//float diff = length(positionFrag.xy/positionFrag.w - positionFrag.xy);
	//float diff = distance(projected.xy/projected.w, projected.xy);
//	vec4 tmp1 = projected.xyzw / projected.w;
//	vec4 worldSpacePosition = INV_CAMERA_MATRIX * tmp1;
//	float diff = distance(worldSpacePosition.xy, projectedPosition);
//	depth = clamp(diff / 32.0, 0.0, 1.0);


//	vec4 viewSpacePosition = POSITION / POSITION.w;
//
//    vec4 worldSpacePosition = INV_CAMERA_MATRIX * viewSpacePosition;
//	float diff = distance(worldSpacePosition.xy, projectedPosition);
//	depth = clamp(diff / 32.0, 0.0, 1.0);
	//depth = (1.0 /projected.w) * 32.0;
	
	// The answer lies somewhere in there maybe...
	// https://stackoverflow.com/a/46118945/998987
//	float z_ndc = projected.z / projected.w;
//	float farZ = 100.0;
//	float nearZ = 0.05;
//	float depth = (((farZ-nearZ) * z_ndc) + nearZ + farZ) / 2.0;
//
//	vec4 viewPosH      = INV_PROJECTION_MATRIX * vec4( z_ndc.x, z_ndc.y, 2.0 * depth - 1.0, 1.0 );
//	vec3 viewPos       = viewPos.xyz / viewPos.w;
//
//	float farZ = 100.0;
//	float nearZ = 0.05;
//	float zDist = farZ - nearZ;
//	//float diff = (1.0 - projected.w) * zDist;
//	//test = clamp(diff / 32.0, 0.0, 1.0);
//
//	//test = (1.0 - projected.w) * zDist;
//	//test = (1.0 - (INV_CAMERA_MATRIX *projected).w) * zDist;
//	//test = (1.0 - POSITION.w) * zDist;
//
//	vec4 wtf = PROJECTION_MATRIX * INV_CAMERA_MATRIX * vec4(projectedPosition, 0.0, 1.0);
//	test = (wtf.w-POSITION.w);//  (1.0 - (POSITION.w - wtf.w)) * zDist;

//	vec4 omg =  INV_PROJECTION_MATRIX * POSITION;
//	if (distance(omg,projected) < 1.0){
//		test = 1.0;
//	}else{
//		test = 0.0;
//	}
	//test = distance(omg,projected);
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
//	if (occlusion < 0.0) {
//		occlusion = 0.0;
//	} else if (occlusion > 1.0) {
//		occlusion = 1.0;
//	}

	// Works. Creates a smooth light cone around the player.
//	float dist = distance(proj.xy / proj.w, light_pos);
//	float dist_fac = clamp(dist / 300.0, 0.0, 1.0);
//	ALPHA = dist_fac * occlusion;


	//vec4 wrld_vertex = INV_PROJECTION_MATRIX * CAMERA_MATRIX * vec4(VERTEX, 1.0);
	//vec4 wrld_vertex = CAMERA_MATRIX * vec4(VERTEX, 1.0);
//	vec4 wrld_vertex = PROJECTION_MATRIX CAMERA_MATRIX * vec4(VERTEX, 1.0);
//	float dist = distance(wrld_vertex.xy / wrld_vertex.w, light_pos);
//	float dist_fac = clamp(dist / 300.0, 0.0, 1.0);
//	ALPHA = dist_fac * occlusion;

	//vec4 wrld_vertex = INV_PROJECTION_MATRIX * CAMERA_MATRIX * vec4(VERTEX, 1.0);
	//float dist = distance(wrld_vertex.xy / wrld_vertex.w, light_pos);
//	if (positionFrag.w <= w_reveal) {
//		ALPHA = 1.0;
//	} else {
//		ALPHA = 0.0;
//	}

	float inset = distance(position, segment);
	float dist = distance(position, light_pos);
	float reveal = 48.0 - 40.0 * clamp(dist / 800.0, 0.0, 1.0);
	
	
	float inset_fac = clamp(inset / reveal, 0.0, 1.0);
	
	
	
	ALBEDO = vec3(occlusion, occlusion, occlusion);
	ALPHA = 1.0 * inset_fac;
	//ALPHA *= 1.75;
	
	
//	if (abs(wrld_vertex.y) < 10.0) {
//		ALPHA = 1.0;
//	} else {
//		ALPHA = 0.0;
//	}
	


	//ALBEDO = vec3(occlusion, occlusion, occlusion);
	//ALBEDO = vec3(0.0, 0.0, 0.0);
	//ALBEDO = vec3(1.0);
	//ALPHA = 1.0;
	//ALPHA = occlusion;
	//ALPHA = 1.0;
	//ALPHA = test;
	
//	vec2 omg = (from.xy / (1.0 - test) - from.xy);
//	//omg.z = 0.0;
//	//omg *= test;
//	if (length(omg) > 0.1) {
//		ALPHA = 1.0;
//	}else{
//		ALPHA=0.0;
//	}
////	PhotonFragOut += vec4(0.25, 0.0, 0.0, 1.0);

//	if (abs(from.z - to.z) < 0.1) {
//		ALPHA = 1.0;
//	}else {
//		ALPHA = 0.0;
//	}
//
//ALPHA = abs(from.z - to.z);

	vec4 t1 = INV_CAMERA_MATRIX * vec4(from, 0.0, 1.0);
	vec4 t2 =  INV_CAMERA_MATRIX * vec4(from, 0.0, test);
	
//	t1 /= t1.w;
//	t2 /= t2.w;
	
//	if (abs(distance(t1.xy, t2.xy)) <32.0) {
//		ALPHA = 1.0;
//	}else {
//		ALPHA = 0.0;
//	}
	//ALPHA = occlusion;
	//ALPHA = 1.0;
	//ALPHA = dist_fac;
}
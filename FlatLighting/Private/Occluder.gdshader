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

// Newer version:
// https://github.com/slembcke/slembcke.github.io/blob/b3f4bb885c2c5db5398844a5a2e19ea83990eb82/js/lighting-2d/soft-shadows.js
// https://github.com/slembcke/slembcke.github.io/blob/b3f4bb885c2c5db5398844a5a2e19ea83990eb82/_posts/2021-08-09-SuperFastSoftShadows.md

uniform vec2 light_pos_array[8];
uniform float light_radius_array[8];

//varying vec2 fragCurrSegment;
varying vec4 fragProjected;
varying vec2 fragNormal;
varying float fragClip;

varying vec2 prevVertexFrag;
varying vec2 nextVertexFrag;
varying mat2 edgeAFrag;
varying mat2 edgeBFrag;

varying vec2 segCoords;

varying float debug;


mat2 edgeMatrix(vec2 vertex, vec2 light_pos, float radius)
{
	// The vector from light to prev or next vertex.
	vec2 v = vertex - light_pos;
	
	// dot product of same vector d is equal to length squared of d.
	// v will be divided by this value. What does it mean?
	//
	// This has maybe someting to do with vector projection?
	// For projecting u on to v the formula is:
	// proj(u) = (dot(u, v) / length(v)^2) * v
	// proj(u) = (dot(u, v) / dot(v, v)) * v
	
	// How do we calculate normalized(v)?
	// norm(v) = v / length(v)
	
	
		// v * a = v / (v.x * v.x + v.y * v.y) 
	// So, v * a is equal to normalized(v), used as the first axis in
	// the edge matrix!
//	float a = 1.0 / dot(v, v);
//
//
//	// This is a
//	float b = 1.0 / (radius * length(v) + 1e-15);
	
	//v = v / (v.x * v.x + v.y * v.y);
//	float vLength = length(v);
//	vec2 axis1 = v / (vLength * vLength);
	vec2 axis1 = v / dot(v, v);
	axis1 = v / (length(v) * length(v));
	//axis1 = v / 100000.0;
//	axis1 = normalize(v);

	vec2 vnorm = normalize(v);
	vec2 axis2 = vec2(-vnorm.y, vnorm.x) / radius;

	return mat2(
		vec2(axis1.x, axis2.x), 
		vec2(axis1.y, axis2.y));
	
	
	// About dot(v, v) -> Must be something with vector projection.
	// See https://math.stackexchange.com/questions/187320/dot-product-of-vectors-and-projections
	
	float a = 1.0 / dot(v, v);
	float b = 1.0 / (radius * length(v) + 1e-15);
	
	
	return mat2(
		vec2(a * v.x, -b * v.y), 
		vec2(a * v.y,  b * v.x));
}

void vertex(){
	// Unpack the vertex data.
	// INV_VIEW_MATRIX = CAMERA_MATRIX
	vec3 cam_pos = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	int index = int(cam_pos.z) - 1;
	
	// Light world coord.
	vec2 lightPosition = light_pos_array[index];
	float light_radius = light_radius_array[index];
	
	// Local model position of current and next vertex specified in CCW order.
	vec2 prevVertex = UV2;
	vec2 nextVertex = UV;
	
	// x=0 -> Prev vertex. x=1 -> Next vertex. y=0 -> On occluder edge. y=1 -> Extruded.
	vec2 segmentCoords = VERTEX.xy;
	
	// Map x to [-1, +1]. Either -1 for prev vertex or +1 for next vertex.
	float projectionOffset = (VERTEX.x - 0.5) * 2.0;
	
	// Transform local vertex coords to world coords.
	prevVertex = (MODEL_MATRIX * vec4(prevVertex, 0.0, 1.0)).xy;
	nextVertex = (MODEL_MATRIX * vec4(nextVertex, 0.0, 1.0)).xy;
	
	// World tangent to current vertex in CCW direction. (Used later)
	vec2 tangent = normalize(nextVertex - prevVertex);
	
	// World normal pointing outwards. Remember: +y is down, -y up. (Used later)
	vec2 normal = vec2(-tangent.y, tangent.x);
	
//	float distToprevVertex = length(lightPos-prevVertex);
//	prevVertex -= normalize(lightPos-prevVertex) * clamp(distToprevVertex, 0.0, 64.0) / 64.0 * 32.0;
//
//	float distTonextVertex = length(lightPos-nextVertex);
//	nextVertex -= normalize(lightPos-nextVertex) * clamp(distTonextVertex, 0.0, 64.0) / 64.0 * 32.0;

	float oneIfOnEdge = 1.0 - segmentCoords.y;
	float oneIfExtruded = segmentCoords.y;

	// Either prev vertex or next vertex world coord.
	vec2 currVertex = mix(prevVertex, nextVertex, segmentCoords.x);
	
	// Light direction in world.
	vec2 lightDirection = normalize(currVertex - lightPosition);

	// Calculate the world coord on the light circle, from which we project the (outer) shadow edge.
	// We offset perpendicular to the light direction.
	// Remember: Vertices are specified in CCW-Order.
	vec2 projectionSource = lightPosition + projectionOffset * light_radius * vec2(lightDirection.y, -lightDirection.x);
	
	// 1) On the edge vertex (segmentCoord.y = 0), unprojected  is the vertex world position (without any offset).
	//    => We set w to 1, meaning no projection. That's why we have to specifiy a position in projected!
	//
	// 2) On the extruded vertex (segmentCoord.y = 1), unprojected is the vector from projection source to the vertex, which
	//    lies on the outer shadow edge (and therfore includes the shadow offset) 
	//	  => We set w to 0, meaning project to infinity. That's why we have to specify a direction in projected!
	vec2 unprojected = currVertex - projectionSource * oneIfExtruded;
	vec4 projected = vec4(unprojected, 0.0, oneIfOnEdge);

	// Camera/View world position.
	float cam_x = INV_VIEW_MATRIX[3][0];
	float cam_y = INV_VIEW_MATRIX[3][1];

	
	// 1) On the edge vertex (projected.w = 1), we transform the vertex position into view space. z is -2.
	// 2) On the extruded vertex (projected.w = 0), there is no transformation. z is 0. It stays a direction. (It's the same direction
	//    in world or view space) (QUESTION: Still bit strange though. And what about camera rotations?).
	POSITION = PROJECTION_MATRIX * vec4(
		projected.x - cam_x * oneIfOnEdge,
		projected.y - cam_y * oneIfOnEdge,
		-2.0 * oneIfOnEdge,
		projected.w);
	
	// Output fragment data!
	
	// Pass world position or extruded world position.
	fragProjected = projected;
	
	// Pass outward normal. This value is constant!
	fragNormal = normal;
	
	// Pass dot product of normal and center between prev and next vertex. This value is constant!
	// We need fragNormal and fragClip for a trick: The result of the dot product of the normal and a point
	// on the edge stays constant! This is because with the dot product, we effectively project the 
	// edge point on the normal and multiply it. Because the edge is perpendicular to the normal,
	// the result is constant.
	// Now: Every point *inside* of the edge, must have a lower value, if you take the dot
	// product with the normal! We can discard all points with a higher value! This happens,
	// when the light intersects the occluder, projecting points outwards! 
	fragClip = dot(normal, (prevVertex + nextVertex)*0.5);
	
	prevVertexFrag = prevVertex;
	nextVertexFrag = nextVertex;
	edgeAFrag = edgeMatrix(prevVertex, lightPosition, light_radius);
	edgeBFrag = edgeMatrix(nextVertex, lightPosition, light_radius);
	
	segCoords = segmentCoords;
}

// Original smootherstep
float smootherstep(float x)
{
  x = clamp(x, 0.0, 1.0);
  return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
}

// https://www.shadertoy.com/view/MlyBWK
float smootherstep2(float edge0, float edge1, float x) 
{
  x = clamp((x - edge0)/(edge1 - edge0), 0., 1.);
  return x * x * x * (x * (x * 6. - 15.) + 10.);
}


float original_smoothstep (float edge0, float edge1, float x)
{
//   if (x < edge0)
//      return 0.0;
//
//   if (x >= edge1)
//      return 1.0;

   // Scale/bias into [0..1] range
//   x = (x - edge0) / (edge1 - edge0);

	x = (x + 1.0) / 2.0;
   return x * x * (3.0 - 2.0 * x);

   //return (x + 1.0) / 2.0 * (x + 1.0) / 2.0 * (3.0 - 2.0 * ((x + 1.0) / 2.0));
	return (x + 1.0) * (x + 1.0) / 4.0 * (3.0 - (x + 1.0));

}

float soften(float t){
	//return t*(3.0 - t*t)*0.25 + 0.5;
	
	
	
	// NOPE?
	// 3.0*x*x - 2.0*x*x*x
	// x * (3.0*x - 2.0*x*x)  // Divide by x
	// 3.0*x - 2.0 * x * x
	// x * (3.0 - 2.0 * x)
	// NOPE?
	
	// edge0 = -1,  edge1 = 1
	//  x = (x - edge0) / (edge1 - edge0);
	// x = (x + 1) / (1 + 1)
	// x = (x + 1) / 2
	//
	// x * x * (3.0 - 2.0 * x)
	//  (x + 1) / 2 * (x + 1) / 2 * (3 - 2 * (x + 1) / 2)
	// (x + 1)^2 / 2 * (3 - 2 * (x + 1) / 2)
	// (x + 1)^2 * 3 / 2  - ((x + 1) * (x + 1)^2)
	// (x^2 + 2x + 2) * 3 - (x + 1) * (x^2 + 2x + 2)
	// (3 * x^2 + 6x + 6) - (x + 1) * (x^2 + 2x + 2)

	return original_smoothstep(-1.0, 1.0, t);
	
	
	//return smoothstep(-1.0, 1.0, t);
	return smootherstep2(-1.0, 1.0, t);
}

float edgef(mat2 m, vec2 delta, float clipped){
	
//	delta = normalize(delta);
	
	vec2 v = m* delta;
	
	// TEST
//	v = v / length(v);
	//v = normalize(v);

	
	
	return (v[0] > 0.0 ? soften(clamp(v[1]/v[0], -1.0, 1.0)) : clipped);
}

void fragment(){
	// World position of fragment.
	vec2 position = fragProjected.xy / fragProjected.w;
	
	// Only shade points within the edge! 
	// In the calculation, everything is constant except world position! For an
	//  explanation see fragClip in thes vertex shader!
	if (dot(fragNormal, position) < fragClip) {
		// position is inside of the occluder edge.

		float occlusionA = edgef(edgeAFrag, position - prevVertexFrag, 1.0);
		float occlusionB = edgef(edgeBFrag, position - nextVertexFrag, 0.0);
		
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
	else {
		// position is outside of the occluder edge.
		discard;
	}
}

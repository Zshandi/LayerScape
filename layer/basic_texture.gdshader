shader_type canvas_item;

uniform sampler2D input_texture : repeat_enable;
uniform float texture_scale = 1.0;


render_mode world_vertex_coords;  // Defers the model-view transformation until after the vertex shader code runs
varying vec2 world_position;  // Use vec3 instead for 3d shaders
void vertex() {
    world_position = VERTEX;
}

void fragment() {
	if (COLOR == vec4(vec3(0.0), 1.0))
	{
		// Black is transparent now
		COLOR = vec4(0.0);
	}
	else
	{
		COLOR = texture(input_texture, world_position/texture_scale);
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}

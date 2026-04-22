shader_type canvas_item;

global uniform float time_pausable;

render_mode world_vertex_coords;  // Defers the model-view transformation until after the vertex shader code runs
varying vec2 world_position;  // Use vec3 instead for 3d shaders
void vertex() {
    world_position = VERTEX;
}

uniform sampler2D scrolling_texture : repeat_enable;
uniform vec4 modulate : source_color;
uniform float scale_multiplier = 4.0;
uniform float rotation_degrees = 0.0;
uniform vec2 scroll_speed = vec2(.1, .2);
uniform float outline_width = 2.0;

float get_alpha_of_pos(vec4 c)
{
	if (c == vec4(vec3(0.0), 1.0))
	{
		return 0.0;
	}
	return c.a;
}


bool on_edge(sampler2D this_texture, vec2 this_uv, vec2 this_tex_pixel_size, float this_outline_width)
{
	// get the texture data for this pixel
	vec4 col = texture(this_texture, this_uv);
	vec2 ps = this_tex_pixel_size;

	float sample_a = get_alpha_of_pos(col);
	// track the min and max alphas of the four neighbouring positions
	float maxa = sample_a;
	float mina = sample_a;

	// -- edge detection logic
	vec2 tex_pos[8] = vec2[8](
		vec2(0.0, -this_outline_width),
		vec2(0.0, this_outline_width),
		vec2(-this_outline_width, 0.0),
		vec2(this_outline_width, 0.0),
		vec2(this_outline_width, -this_outline_width),
		vec2(-this_outline_width, this_outline_width),
		vec2(this_outline_width, this_outline_width),
		vec2(-this_outline_width, -this_outline_width)
	);

	for (int i = 0; i < 8; i++) {
		vec2 offset_uv = this_uv + tex_pos[i] * ps;
		float sample_a;
		if (offset_uv.x < 0.0 || offset_uv.x > 1.0 || offset_uv.y < 0.0 || offset_uv.y > 1.0) {
			sample_a = 0.0;
		} else {
			sample_a = get_alpha_of_pos(texture(this_texture, offset_uv));
		}
		maxa = max(sample_a, maxa);
		mina = min(sample_a, mina);

	}

	return maxa - mina > 0.0 && sample_a > 0.0;

}

void fragment()
{
	// if this pixel is black or not on the edge of a shape, make it trasnparent
	if (COLOR == vec4(vec3(0.0), 1.0))
	{
		// Black is transparent now
		COLOR = vec4(0.0);
	}

	// scale the uv
	vec2 tiled_uv = world_position * scale_multiplier + scroll_speed * time_pausable;
	// vec2 world_uv = SCREEN_UV * vec2(textureSize(scrolling_texture, 0)) / scale_multiplier + scroll_speed * TIME;
	// vec2 tiled_uv = world_uv / scale_multiplier + scroll_speed * TIME;

	// rotate the UV
	float angle = radians(rotation_degrees);
	vec2 centered_uv = tiled_uv - 0.5;
	float cos_angle = cos(angle);
	float sin_angle = sin(angle);
	vec2 rotated_uv = vec2(
		centered_uv.x * cos_angle - centered_uv.y * sin_angle,
		centered_uv.x * sin_angle + centered_uv.y * cos_angle
	) + 0.5;

	if (on_edge(TEXTURE, UV, TEXTURE_PIXEL_SIZE, outline_width))
	{
		vec4 tex = texture(scrolling_texture, rotated_uv);
		COLOR = vec4(modulate.rgb, tex.a * modulate.a);
	}
	else
	{
		COLOR = vec4(0.0);
	}

}

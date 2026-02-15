shader_type canvas_item;

uniform sampler2D scrolling_texture : repeat_enable;
uniform vec4 modulate : source_color;
uniform float scale_multiplier = 4.0;
uniform float rotation_degrees = 0.0;
uniform vec2 scroll_speed = vec2(.1, .2);
uniform float outline_width = 2.0;

float get_alpha_of_pos(vec4 this_pos)
{
	if (this_pos == vec4(vec3(0.0), 1.0))
	{
		return 0.0;
	}
	return this_pos.a;
}

bool on_edge(sampler2D this_texture, vec2 this_uv, vec2 this_tex_pixel_size)
{
	// get the texture data for this pixel
	vec4 col = texture(this_texture, this_uv);
	vec2 ps = this_tex_pixel_size;

	// track the min and max alphas of the four neighbouring positions
	float maxa = col.a;
	float mina = col.a;
	float a;

	// -- edge detection logic

	vec2 tex_pos[4] = vec2[4](
		vec2(0.0, -outline_width),
		vec2(0.0, outline_width),
		vec2(-outline_width, 0.0),
		vec2(outline_width, 0.0)
	);

	for (int i = 0; i < 4; i++) {
		vec4 this_pos = texture(this_texture, this_uv + tex_pos[i] * a);
		a = get_alpha_of_pos(this_pos);
		maxa = max(a, maxa);
		mina = min(a, mina);
	}

	return (maxa - mina == 0.0);

}

// bool on_edge(sampler2D this_texture, vec2 this_uv, vec2 this_tex_pixel_size)
// {
// 	// get the texture data for this pixel
// 	vec4 col = texture(this_texture, this_uv);
// 	vec2 ps = this_tex_pixel_size;

// 	// -- edge detection logic

// 	// track the min and max alphas of the four neighbouring positions
// 	float maxa = col.a;
// 	float mina = col.a;

// 	float a = texture(this_texture, this_uv + vec2(0.0, -outline_width) * ps).a;
// 	maxa = max(a, maxa);
// 	mina = min(a, mina);

// 	// below the current pixel
// 	a = texture(this_texture, this_uv + vec2(0.0, outline_width) * ps).a;
// 	maxa = max(a, maxa);
// 	mina = min(a, mina);

// 	// left of the current pixel
// 	a = texture(this_texture, this_uv + vec2(-outline_width, 0.0) * ps).a;
// 	maxa = max(a, maxa);
// 	mina = min(a, mina);

// 	// right of the current pixel
// 	a = texture(this_texture, this_uv + vec2(outline_width, 0.0) * ps).a;
// 	maxa = max(a, maxa);
// 	mina = min(a, mina);

// 	return (maxa - mina == 0.0);
// }

void fragment()
{
	// make black transparent
	if (COLOR == vec4(vec3(0.0), 1.0))
	{
		// Black is transparent now
		COLOR = vec4(0.0);
	}
	if (on_edge(TEXTURE, UV, TEXTURE_PIXEL_SIZE))
	{
		COLOR = vec4(0.0);
	}

	// // scale the uv
	// vec2 tiled_uv = UV * scale_multiplier + scroll_speed * TIME;

	// // rotate the UV
	// float angle = radians(rotation_degrees);
	// vec2 centered_uv = tiled_uv - 0.5;
	// float cos_angle = cos(angle);
	// float sin_angle = sin(angle);
	// vec2 rotated_uv = vec2(
	// 	centered_uv.x * cos_angle - centered_uv.y * sin_angle,
	// 	centered_uv.x * sin_angle + centered_uv.y * cos_angle
	// ) + 0.5;

	// if (!on_edge(scrolling_texture, rotated_uv, TEXTURE_PIXEL_SIZE))
	// {
	// 	COLOR = vec4(0.0);
	// }
	// else 
	// {
	// 	vec4 tex = texture(scrolling_texture, rotated_uv);
	// 	COLOR = vec4(modulate.rgb, tex.a * modulate.a);
	// }
}

// void fragment() {
// 	// make black transparent
// 	if (COLOR == vec4(vec3(0.0), 1.0))
// 	{
// 		// Black is transparent now
// 		COLOR = vec4(0.0);
// 	}
// 	else
// 	{
// 		vec2 tiled_uv = UV * scale_multiplier + scroll_speed * TIME;

// 		// rotate the UV
// 		float angle = radians(rotation_degrees);
// 		vec2 centered_uv = tiled_uv - 0.5;
// 		float cos_angle = cos(angle);
// 		float sin_angle = sin(angle);
// 		vec2 rotated_uv = vec2(
// 			centered_uv.x * cos_angle - centered_uv.y * sin_angle,
// 			centered_uv.x * sin_angle + centered_uv.y * cos_angle
// 		) + 0.5;


// 		if (!on_edge(scrolling_texture, rotated_uv, TEXTURE_PIXEL_SIZE))
// 		{
// 			COLOR = vec4(0.0);
// 		}
// 		else 
// 		{
// 			vec4 tex = texture(scrolling_texture, rotated_uv);
// 			COLOR = vec4(modulate.rgb, tex.a * modulate.a);
// 		}

// 	}
// }


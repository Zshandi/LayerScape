shader_type canvas_item;

uniform sampler2D scrolling_texture : repeat_enable;
uniform vec4 modulate : source_color;
uniform float scale_multiplier = 4.0;
uniform float rotation_degrees = 0.0;
uniform vec2 scroll_speed = vec2(1, 2);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// make black transparent
	if (COLOR == vec4(vec3(0.0), 1.0))
	{
		// Black is transparent now
		COLOR = vec4(0.0);
	}
	else
	{
		vec2 tiled_uv = UV * scale_multiplier + scroll_speed * TIME;

		// rotate the UV
		float angle = radians(rotation_degrees);
		vec2 centered_uv = tiled_uv - 0.5;
		float cos_angle = cos(angle);
		float sin_angle = sin(angle);
		vec2 rotated_uv = vec2(
			centered_uv.x * cos_angle - centered_uv.y * sin_angle,
			centered_uv.x * sin_angle + centered_uv.y * cos_angle
		) + 0.5;

		vec4 tex = texture(scrolling_texture, rotated_uv);
		COLOR = vec4(modulate.rgb, tex.a * modulate.a);
	}
}
/*
void fragment() {
	// Called for every pixel the material is visible on.
	if (COLOR == vec4(vec3(0.0), 1.0))
	{
		// Black is transparent now
		COLOR = vec4(0.0);
	}
	else
	{
		float x_val = UV.x / width;
		float y_val = UV.y / height;
		float time_val = TIME / frequency;
		float progress = mod(x_val + y_val + time_val, 1);
		
		float brightness = 0.0;
		if (progress <= 0.5)
		{
			brightness = progress * 2.0;
		}
		else
		{
			brightness = (1.0 - progress) * 2.0;
		}
		// Update this with whatever we want the final result to be
		COLOR = vec4(vec3(brightness), 1.0);
	}
}
*/

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}

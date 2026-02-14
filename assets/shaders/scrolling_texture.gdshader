shader_type canvas_item;

uniform sampler2D scrolling_texture : repeat_enable;
uniform vec4 modulate : source_color;
uniform float scale_multiplier = 4.0;
uniform float rotation_degrees = 0.0;
uniform vec2 scroll_speed = vec2(.1, .2);


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


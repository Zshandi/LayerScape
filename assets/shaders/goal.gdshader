shader_type canvas_item;

global uniform float time_pausable;

uniform float frequency = 1.0;
uniform float frequency_offset = 0.0;
uniform float thickness = 10.0;
uniform float spacing = 50.0;

uniform float fade_dist_start = 40.0;
uniform float fade_dist_end = 80.0;

uniform float original_distance = 10.0;

uniform int samples_per_dimension = 4;

void vertex() {
	// Called for every vertex the material is visible on.
}

float sample(vec2 uv) {
	float total_repeat_distance = thickness + spacing;
	
	float relative_height = 1.0 - uv.y;
	float relative_width = 2.0 * (uv.x > 0.5 ? uv.x - 0.5 : 0.5 - uv.x);
	float relative_size = max(relative_height, relative_width);
	
	float dist = original_distance / relative_size;
	
	float dist_time = dist - ((time_pausable + frequency_offset) * frequency * total_repeat_distance);

	float relative_dist = dist_time - original_distance;

	float modulo_dist = mod(relative_dist, total_repeat_distance);

	if (modulo_dist <= thickness) {
		float result = modulo_dist / thickness;
		if (dist > fade_dist_end) {
			return 0.0;
		}
		else if (dist > fade_dist_start) {
			float fade_dist_total = fade_dist_end - fade_dist_start;
			float relative_dist_fade = dist - fade_dist_start;
			result *= 1.0 - (relative_dist_fade / fade_dist_total);
		}
		return result;
	}
	else {
		return 0.0;
	}
}

float sample_antialiased(vec2 uv, int samples_per_dim, vec2 pixel_size) {
	float sample_width = pixel_size.x / float(samples_per_dim);
	float sample_height = pixel_size.y / float(samples_per_dim);

	float sample_total = 0.0;
	for (int x_offset_count = 0; x_offset_count < samples_per_dim; x_offset_count++) {
		for (int y_offset_count = 0; y_offset_count < samples_per_dim; y_offset_count++) {
			float x_offset = float(x_offset_count) * sample_width;
			float y_offset = float(y_offset_count) * sample_height;
			sample_total += sample(uv + vec2(x_offset, y_offset));
		}
	}
	return sample_total / float(samples_per_dim * samples_per_dim);
}

void fragment() {
	float brightness = sample(UV);
	COLOR *= vec4(vec3(brightness), 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}

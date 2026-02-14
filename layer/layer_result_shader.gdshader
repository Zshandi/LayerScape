shader_type canvas_item;

uniform float width = 0.1;
uniform float height = 0.1;
uniform float frequency = 10.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

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

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}

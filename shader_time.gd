extends Node

var current_time: float = 0

func _process(delta: float) -> void:
	if not get_tree().paused:
		var max_time: float = ProjectSettings.get_setting("rendering/limits/time/time_rollover_secs", 3600.0)

		current_time += delta
		if current_time >= max_time:
			current_time -= max_time
		
		RenderingServer.global_shader_parameter_set("time_pausable", current_time)

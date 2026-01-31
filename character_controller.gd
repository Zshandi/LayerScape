extends CharacterBody2D
class_name CharacterController

var move_speed := 600
var jump_speed := 1000
var variable_jump_down_multiplier := 1.8

var is_jumping := false
var applied_gravity: Vector2

func _physics_process(delta: float) -> void:
	var move_dir := 0.0
	if Input.is_action_pressed("move_right"):
		move_dir += 1
	if Input.is_action_pressed("move_left"):
		move_dir -= 1
	
	applied_gravity = get_gravity()

	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y -= jump_speed
		is_jumping = true
		applied_gravity = get_gravity()
	elif is_jumping:
		if is_on_floor():
			is_jumping = false
			applied_gravity = get_gravity()
		elif not Input.is_action_pressed("jump"):
			# Variable jump height
			if velocity.y < 0:
				velocity.y = 0
			applied_gravity = get_gravity() * variable_jump_down_multiplier
			
	
	velocity.x = move_dir * move_speed
	velocity += applied_gravity * delta
	
	move_and_slide()

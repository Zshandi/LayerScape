extends CharacterBody2D
class_name Character

signal reached_goal

const goal_y_tolerance: float = 20
const required_goal_time: float = 0.01

var move_speed := 600
var jump_speed := 1000
var variable_jump_down_multiplier := 1.8

@export
var goal_node: Goal
@export
var scale_nodes: Array[Node2D]

var shape_rect: Rect2:
	get:
		var rect: Rect2 = %Shape.shape.get_rect()
		rect.position = %Shape.global_position
		return rect

var is_jumping := false
var applied_gravity: Vector2

var is_touching_goal: bool = false
var goal_timer: float = required_goal_time

var move_dir := 0.0

var next_velocity := Vector2.ZERO

@onready
var sprite_scale: Vector2 = %Sprite.scale

func _ready() -> void:
	goal_node.body_entered.connect(_on_goal_body_entered)
	goal_node.body_exited.connect(_on_goal_body_exited)

func can_win() -> bool:
	return is_on_floor() and is_touching_goal and \
		# Ensure the goal is near the floor as well
		global_position.y >= goal_node.global_position.y - goal_y_tolerance and \
		global_position.y <= goal_node.global_position.y + goal_y_tolerance

func move_toward_center_goal(delta: float) -> bool:
	var target := goal_node.global_position.x
	global_position.x = move_toward(global_position.x, target, move_speed * 0.5 * delta)
	if is_equal_approx(global_position.x, target):
		return true
	else:
		move_dir = sign(target - global_position.x)
		return false

func _physics_process(delta: float) -> void:
	# Check win condition
	if can_win():
		if move_toward_center_goal(delta):
			# Count down once in center
			goal_timer -= delta
			if goal_timer <= 0:
				%Sprite.process_mode = Node.PROCESS_MODE_ALWAYS
				# Don't process anymore, since we've won
				process_mode = Node.PROCESS_MODE_DISABLED
				# Play sound
				%ReachedGoal.play()
				# Play animation
				var modulate_transparent := modulate
				modulate_transparent.a = 0
				var tween := get_tree().create_tween()
				tween.set_parallel(true)
				tween.tween_property(self , "scale", Vector2(0.2, 0.2), 0.5)
				tween.tween_property(self , "modulate", modulate_transparent, 0.5)
				await tween.finished
				reached_goal.emit()
		
		# Only apply gravity if touching goal
		velocity.x = 0
		velocity += applied_gravity * delta
		move_and_slide()
		return
	else:
		goal_timer = required_goal_time
	
	applied_gravity = get_gravity()

	# Check for falling off
	if global_position.y > get_viewport_rect().size.y + 50:
		get_tree().paused = true
		await get_tree().create_timer(0.3).timeout
		# TODO: Maybe play animation / sound
		get_tree().paused = false
		LevelManager.reload_level()
	
	# Check inputs
	move_dir = 0
	if Input.is_action_pressed("move_right"):
		move_dir += 1
	if Input.is_action_pressed("move_left"):
		move_dir -= 1
	velocity.x = move_dir * move_speed

	# Apply jump mechanics
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
	
	# Apply movement and gravity
	velocity += applied_gravity * delta
	move_and_slide()

func get_next_velocity(delta: float) -> Vector2:
	next_velocity = velocity

	applied_gravity = get_gravity()

	# Check for falling off
	if global_position.y > get_viewport_rect().size.y + 50:
		get_tree().paused = true
		await get_tree().create_timer(0.3).timeout
		# TODO: Maybe play animation / sound
		get_tree().paused = false
		LevelManager.reload_level()
	
	# Check inputs
	move_dir = 0
	if Input.is_action_pressed("move_right"):
		move_dir += 1
	if Input.is_action_pressed("move_left"):
		move_dir -= 1
	next_velocity.x = move_dir * move_speed

	# Apply jump mechanics
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		next_velocity.y -= jump_speed
		is_jumping = true
		applied_gravity = get_gravity()
	elif is_jumping:
		if is_on_floor():
			is_jumping = false
			applied_gravity = get_gravity()
		elif not Input.is_action_pressed("jump"):
			# Variable jump height
			if next_velocity.y < 0:
				next_velocity.y = 0
			applied_gravity = get_gravity() * variable_jump_down_multiplier
	
	next_velocity += applied_gravity * delta
	return next_velocity

func _on_goal_body_entered(body: Node2D) -> void:
	if body != self: return
	is_touching_goal = true

func _on_goal_body_exited(body: Node2D) -> void:
	if body != self: return
	is_touching_goal = false

const goal_tolerance := 5
func is_shape_a_within_b(a: Rect2, b: Rect2) -> bool:
	var horizontal_within := a.position.x + goal_tolerance >= b.position.x and \
		a.position.x + a.size.x <= b.position.x + b.size.x + goal_tolerance
	var vertical_within := a.position.y + goal_tolerance >= b.position.y and \
		a.position.y + a.size.y <= b.position.y + b.size.y + goal_tolerance
	return horizontal_within and vertical_within

func is_within_goal() -> bool:
	# TODO: Fix this!
	return is_shape_a_within_b(shape_rect, goal_node.shape_rect)

func _process(_delta: float) -> void:
	if move_dir != 0:
		$Sprite.scale.x = sign(move_dir) * sprite_scale.x
	
	if is_on_floor():
		if move_dir == 0:
			$Sprite.play("idle")
		else:
			$Sprite.play("run")
	else:
		if velocity.y < 0:
			$Sprite.play("jump_up")
		else:
			$Sprite.play("fall_down")

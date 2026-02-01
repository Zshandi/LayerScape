extends CharacterBody2D
class_name CharacterController

signal reached_goal

@export
var goal_node: Goal
@export
var scale_nodes: Array[Node2D]

var shape_rect: Rect2:
	get:
		var rect: Rect2 = %Shape.shape.get_rect()
		rect.position = global_position
		return rect

const required_goal_time: float = 0.2

var move_speed := 600
var jump_speed := 1000
var variable_jump_down_multiplier := 1.8

var is_jumping := false
var applied_gravity: Vector2

var is_touching_goal: bool = false

var goal_timer: float = required_goal_time

func _ready() -> void:
	goal_node.body_entered.connect(_on_goal_body_entered)
	goal_node.body_exited.connect(_on_goal_body_exited)

func can_win() -> bool:
	return is_on_floor() and is_touching_goal

func move_toward_center_goal(delta: float) -> bool:
	var target := goal_node.global_position.x
	global_position.x = move_toward(global_position.x, target, move_speed * 0.5 * delta)
	return is_equal_approx(global_position.x, target)

func _physics_process(delta: float) -> void:
	applied_gravity = get_gravity()

	# Check win condition
	if can_win():
		if move_toward_center_goal(delta):
			# Count down once in center
			goal_timer -= delta
			if goal_timer <= 0:
				move_toward_center_goal(delta)
				process_mode = Node.PROCESS_MODE_DISABLED
				# Play animation
				var modulate_transparent := modulate
				modulate_transparent.a = 0
				var tween := get_tree().create_tween()
				tween.set_parallel(true)
				tween.tween_property(self , "scale", Vector2(0.2, 0.2), 0.5)
				tween.tween_property(self , "modulate", modulate_transparent, 0.5)
				await tween.finished
				reached_goal.emit()
		
		# Only apply gravity
		velocity.x = 0
		velocity += applied_gravity * delta
		move_and_slide()
		return
	else:
		goal_timer = required_goal_time
	
	# Check inputs
	var move_dir := 0.0
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

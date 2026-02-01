extends CharacterBody2D
class_name CharacterController

signal reached_goal

@export
var goal_node: Goal

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

func _physics_process(delta: float) -> void:
	# Check win condition
	if is_on_floor() and is_touching_goal and is_within_goal():
		goal_timer -= delta
		if goal_timer <= 0:
			reached_goal.emit()
	else:
		goal_timer = required_goal_time
	
	# Check inputs
	var move_dir := 0.0
	if not (is_on_floor() and is_touching_goal and is_within_goal()):
		# Stop moving once in goal
		if Input.is_action_pressed("move_right"):
			move_dir += 1
		if Input.is_action_pressed("move_left"):
			move_dir -= 1
	
	applied_gravity = get_gravity()

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
	velocity.x = move_dir * move_speed
	velocity += applied_gravity * delta
	
	move_and_slide()

func _on_goal_body_entered(body: Node2D) -> void:
	if body != self: return
	is_touching_goal = true

func _on_goal_body_exited(body: Node2D) -> void:
	if body != self: return
	is_touching_goal = false

func is_shape_a_within_b(a: Rect2, b: Rect2) -> bool:
	var horizontal_within := a.position.x > b.position.x and \
		a.position.x + a.size.x < b.position.x + b.size.x
	var vertical_within := a.position.y > b.position.y and \
		a.position.y + a.size.y < b.position.y + b.size.y
	return horizontal_within and vertical_within

func is_within_goal() -> bool:
	return is_shape_a_within_b(shape_rect, goal_node.shape_rect)

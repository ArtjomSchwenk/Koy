# ProtoController v1.0 by Brackeys
# CC0 License
# Extended: sprint fix, dash added, uses built-in ui_* input actions

extends CharacterBody3D

@export var can_move : bool = true
@export var has_gravity : bool = true
@export var can_jump : bool = true
@export var can_sprint : bool = true
@export var can_dash : bool = true
@export var can_freefly : bool = false

@export_group("Speeds")
@export var look_speed : float = 0.002
@export var base_speed : float = 7.0
@export var jump_velocity : float = 4.5
@export var sprint_speed : float = 10.0
@export var freefly_speed : float = 25.0

@export_group("Dash")
@export var dash_speed : float = 18.0
@export var dash_duration : float = 0.15
@export var dash_cooldown : float = 0.6
@export var dash_only_on_floor : bool = false

@export_group("Input Actions")
@export var input_left : String = "ui_left"
@export var input_right : String = "ui_right"
@export var input_forward : String = "ui_up"
@export var input_back : String = "ui_down"
@export var input_jump : String = "ui_accept"
@export var input_sprint : String = "sprint"
@export var input_dash : String = "dash"
@export var input_freefly : String = "freefly"

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false

# Dash state
var dashing : bool = false
var dash_time_left : float = 0.0
var dash_cd_left : float = 0.0
var dash_dir : Vector3 = Vector3.ZERO

@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider

func _ready() -> void:
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()

	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)

	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func _physics_process(delta: float) -> void:
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return

	# Dash cooldown
	if dash_cd_left > 0.0:
		dash_cd_left = max(0.0, dash_cd_left - delta)

	# Gravity
	if has_gravity and not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if can_jump and Input.is_action_just_pressed(input_jump) and is_on_floor():
		velocity.y = jump_velocity

	# Start dash
	if can_dash and (not dashing) and dash_cd_left <= 0.0 and Input.is_action_just_pressed(input_dash):
		if (not dash_only_on_floor) or is_on_floor():
			var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
			var wish_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

			# If no input direction, dash forward
			if wish_dir == Vector3.ZERO:
				wish_dir = -transform.basis.z
				wish_dir.y = 0
				wish_dir = wish_dir.normalized()

			dashing = true
			dash_time_left = dash_duration
			dash_cd_left = dash_cooldown
			dash_dir = wish_dir

	# Apply dash movement
	if dashing:
		dash_time_left -= delta
		velocity.x = dash_dir.x * dash_speed
		velocity.z = dash_dir.z * dash_speed
		if dash_time_left <= 0.0:
			dashing = false

	# Sprint speed (only when not dashing)
	if can_sprint and Input.is_action_pressed(input_sprint) and not dashing:
		move_speed = sprint_speed
	else:
		move_speed = base_speed

	# Normal movement (skip while dashing)
	if can_move and not dashing:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir != Vector3.ZERO:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	elif not can_move:
		velocity.x = 0
		velocity.y = 0
		velocity.z = 0

	move_and_slide()

func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_dash and not InputMap.has_action(input_dash):
		push_error("Dash disabled. No InputAction found for input_dash: " + input_dash)
		can_dash = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false


func _on_dash_cooldown_timeout() -> void:
	pass # Replace with function body.

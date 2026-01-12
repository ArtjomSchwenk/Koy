extends CharacterBody3D


@export var speed: float = 5.0;
@export var runModif: float = 5.0;
@export var isRunning: bool = false;
@export var jump_Velocity: float = 4.5;
@export var camera_sensitivity: float = 0.8;
@export var isPaused: bool = false;
@onready var cameraGimbal: Node3D = get_node("cameraGimbal");


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta;

	# Handle jump.
	if Input.is_action_just_pressed("ui_select") and is_on_floor():
		velocity.y = jump_Velocity;

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down");
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized();
	if is_on_floor():
		if direction:
			velocity.x = direction.x * (speed + int(isRunning) * runModif);
			velocity.z = direction.z * (speed + int(isRunning) * runModif);
		else:
			velocity.x = move_toward(velocity.x, 0, speed);
			velocity.z = move_toward(velocity.z, 0, speed);
	if Input.is_action_just_pressed("ui_cancel"): ##Escape button btw
		if !isPaused:
			pauseGame();
		elif isPaused:
			unpauseGame();
	move_and_slide()

func _unhandled_input(event):
	##Mouse movement
	if event is InputEventMouseMotion:
		##horizontal; turns the entire player
		rotation_degrees.y -= event.screen_relative.x * camera_sensitivity; 
		##vertical; turns only camera
		cameraGimbal.rotation_degrees.x -= event.screen_relative.y * camera_sensitivity;
		cameraGimbal.rotation_degrees.x = clamp(cameraGimbal.rotation_degrees.x, -30.0, 20.0);
	## Running
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_SHIFT:
			isRunning = true;
		else:
			isRunning = false;
func pauseGame():
	isPaused = true;
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
	
func unpauseGame():
	isPaused = false;
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);

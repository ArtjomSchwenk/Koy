extends CharacterBody3D


@onready var player: CharacterBody3D = $"."

@export_group("Movement")
@export var speed: float = 5.0;
@export var runModif: float = 5.0;
@export var isRunning: bool = false;
@export var isDashing: bool = false;
@export var canDash: bool = true;
@export var dash_Force: float = 5.0;
@onready var dashCooldown: Timer = $dashCooldown;
@onready var dashDuration: Timer = $dashDuration;
@export var jump_Velocity: float = 4.5;

var direction: Vector3 = Vector3(0,0,0);
@export_group("Settings")
@export var camera_sensitivity: float = 0.8;
@export var isPaused: bool = false;
@export var dash_Keybind: int = KEY_E;
@export var run_Keybind: int = KEY_SHIFT;
@export var jump_Keybind: int = KEY_SPACE;

@onready var cameraGimbal: Node3D = get_node("cameraGimbal");


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta;

	# Handle jump.
	if Input.is_key_label_pressed(jump_Keybind) and is_on_floor():
		velocity.y = jump_Velocity;

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down");
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized();
	if isDashing:
		velocity = -player.global_transform.basis.z.normalized() * (speed + dash_Force) ;
	elif direction:
		velocity.x = direction.x * (speed + int(isRunning) * runModif);
		velocity.z = direction.z * (speed + int(isRunning) * runModif);
	else:
		velocity.x = 0.0;
		velocity.z = 0.0;
		
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
	
	if event is InputEventKey:
		## Running
		if event.keycode == run_Keybind:
			if event.pressed:
				isRunning = true;
			else:
				isRunning = false;
		## Dashing
		if event.keycode == dash_Keybind:
			if event.pressed and canDash:
				dashCooldown.start();
				canDash = false;
				isDashing = true;
				dashDuration.start();
				print("we dashing :D");
				
			
		
func pauseGame():
	isPaused = true;
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
	
func unpauseGame():
	isPaused = false;
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);


func _on_dash_cooldown_timeout() -> void:
	canDash = true;
func _on_dash_duration_timeout() -> void:
	print(isDashing);
	isDashing = false;
	print(isDashing);
	

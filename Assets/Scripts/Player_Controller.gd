extends CharacterBody3D

@onready var gm: GameManager = GameManager;
@onready var player: CharacterBody3D = $".";

@export_group("Movement")
@export var speed: float = 4.0;          # bisschen schneller laufen
@export var runModif: float = 5.0;
@export var isRunning: bool = false;
@export var isDashing: bool = false;
@export var canDash: bool = true;

@export var dash_Force: float = 8.0;    # WAR 5.0 -> jetzt spürbar
@export var dash_air_multiplier: float = 1.15; # NEU: in der Luft leicht stärker

@onready var dashCooldown: Timer = $dashCooldown;
@onready var dashDuration: Timer = $dashDuration;

@export var jump_Velocity: float = 15.0; # WAR 8.5 -> jetzt richtig hoch

# Gravity / Feel
@export var gravity_force: float = 30.0;
@export var fall_multiplier: float = 1.8;
@export var low_jump_multiplier: float = 2.2;

var direction: Vector3 = Vector3(0,0,0);

@export_group("Settings")
@export var camera_sensitivity: float = 0.8;
@export var isPaused: bool = false;
@export var interact_Keybind: int = KEY_E;
@export var dash_Keybind: int = KEY_CTRL;
@export var run_Keybind: int = KEY_SHIFT;
@export var jump_Keybind: int = KEY_SPACE;

@onready var cameraGimbal: Node3D = get_node("cameraGimbal");
@onready var raycast: RayCast3D = get_node("cameraGimbal/head/RayCast3D");
var canInteract: bool = false;


func _ready() -> void:
	raycast.add_exception(self);

func _physics_process(delta: float) -> void:

	if raycast.is_colliding():
		var target = raycast.get_collider();
		if target is Interactable:
			canInteract = true;
			gm.interactionAvailable.emit(target.prompt_message);
	else:
		canInteract = false;
		gm.interactionAvailable.emit("");

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity_force * delta

		if velocity.y < 0.0:
			velocity.y -= gravity_force * (fall_multiplier - 1.0) * delta
		elif velocity.y > 0.0 and not Input.is_key_pressed(jump_Keybind):
			velocity.y -= gravity_force * (low_jump_multiplier - 1.0) * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0

	# Jump
	if Input.is_key_pressed(jump_Keybind) and is_on_floor():
		velocity.y = jump_Velocity

	# Move
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down");
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized();

	if isDashing:
		var dash_dir: Vector3 = -player.global_transform.basis.z.normalized();
		var dash_speed: float = (speed + dash_Force);

		# in der Luft bisschen mehr Kick, damit es sich nicht “weggebremst” anfühlt
		if not is_on_floor():
			dash_speed *= dash_air_multiplier;

		velocity.x = dash_dir.x * dash_speed;
		velocity.z = dash_dir.z * dash_speed;

	elif direction:
		velocity.x = direction.x * (speed + int(isRunning) * runModif);
		velocity.z = direction.z * (speed + int(isRunning) * runModif);
	else:
		velocity.x = 0.0;
		velocity.z = 0.0;

	move_and_slide()


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.screen_relative.x * camera_sensitivity;
		cameraGimbal.rotation_degrees.x -= event.screen_relative.y * camera_sensitivity;
		cameraGimbal.rotation_degrees.x = clamp(cameraGimbal.rotation_degrees.x, -30.0, 20.0);

	if event is InputEventKey:
		if event.keycode == run_Keybind:
			if event.pressed:
				isRunning = true;
			else:
				isRunning = false;

		if event.keycode == dash_Keybind:
			if event.pressed and canDash:
				dashCooldown.start();
				canDash = false;
				isDashing = true;
				dashDuration.start();
				print("we dashing :D");

		if event.keycode == KEY_ESCAPE:
			pauseGame();

		if event.is_action_pressed("interact"):
			gm.interactionTrigger.emit(raycast.get_collider())


func pauseGame():
	isPaused = true;
	gm.setGameState(gm.GAME_STATE.PAUSE);

func _on_dash_cooldown_timeout() -> void:
	canDash = true;

func _on_dash_duration_timeout() -> void:
	isDashing = false;

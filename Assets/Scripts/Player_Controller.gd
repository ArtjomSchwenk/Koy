extends CharacterBody3D

@onready var gm: GameManager = GameManager;
@onready var player: CharacterBody3D = $".";

@export_group("Movement")
@export var speed: float = 4.0;
@export var runModif: float = 5.0;
@export var isRunning: bool = false;
@export var isDashing: bool = false;
@export var canDash: bool = true;

@export var dash_Force: float = 8.0;
@export var dash_air_multiplier: float = 1.15;
@onready var dashCooldown: Timer = $dashCooldown;
@onready var dashDuration: Timer = $dashDuration;

@export var jump_Velocity: float = 15.0;

@export var gravity_force: float = 30.0;
@export var fall_multiplier: float = 1.8;
@export var low_jump_multiplier: float = 2.2;

@export var isClimbing: bool = false;
@export var climb_speed: float = 2.0;

@export var snap_back_offset: float = 0.45;
@export var snap_down_offset: float = 0.65;

@export var pullup_time: float = 2.0;
@export var pullup_up: float = 1.2;
@export var pullup_forward: float = 0.6;

@export var snap_time: float = 0.08; # kurze Einrast Phase statt Teleport

var isPullingUp: bool = false;
var pullup_t: float = 0.0;

var pullup_from: Vector3 = Vector3.ZERO;
var pullup_mid: Vector3 = Vector3.ZERO;
var pullup_to: Vector3 = Vector3.ZERO;

var pullup_stage: int = 0; # 0 = zum Snap Punkt 1 = hoch und vor

# Multi Ray Setup
@onready var ray_chest_mid: RayCast3D = $climbChecksChest/ray_chest_mid
@onready var ray_chest_left: RayCast3D = $climbChecksChest/ray_chest_left
@onready var ray_chest_right: RayCast3D = $climbChecksChest/ray_chest_right

@onready var ray_head_mid: RayCast3D = $climbCheckHead/ray_head_mid
@onready var ray_head_left: RayCast3D = $climbCheckHead/ray_head_left
@onready var ray_head_right: RayCast3D = $climbCheckHead/ray_head_right

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

var jumpTapped: bool = false;


func _ready() -> void:
	raycast.add_exception(self);


func _get_grab_data() -> Dictionary:
	var pairs = [
		{"chest": ray_chest_mid, "head": ray_head_mid},
		{"chest": ray_chest_left, "head": ray_head_left},
		{"chest": ray_chest_right, "head": ray_head_right},
	]

	for p in pairs:
		var c: RayCast3D = p["chest"]
		var h: RayCast3D = p["head"]
		if c != null and h != null and c.is_colliding() and not h.is_colliding():
			return {
				"ok": true,
				"point": c.get_collision_point(),
				"normal": c.get_collision_normal()
			}

	return {"ok": false}


func _start_pullup(grab_point: Vector3, grab_normal: Vector3) -> void:
	isClimbing = true
	isPullingUp = true
	pullup_stage = 0
	pullup_t = 0.0

	isDashing = false
	velocity = Vector3.ZERO

	pullup_from = global_position
	pullup_mid = grab_point + grab_normal * snap_back_offset + Vector3(0, -snap_down_offset, 0)
	pullup_to = pullup_mid + Vector3(0, pullup_up, 0) + (-global_transform.basis.z.normalized() * pullup_forward)


func _physics_process(delta: float) -> void:

	# Interact
	if raycast.is_colliding():
		var target = raycast.get_collider();
		if target is Interactable:
			canInteract = true;
			gm.interactionAvailable.emit(target.prompt_message);
	else:
		canInteract = false;
		gm.interactionAvailable.emit("");

	# Grab check
	var can_grab: bool = false
	var grab_point: Vector3 = Vector3.ZERO
	var grab_normal: Vector3 = Vector3.ZERO

	if not is_on_floor() and not isClimbing and not isPullingUp:
		var gd := _get_grab_data()
		if gd["ok"]:
			can_grab = true
			grab_point = gd["point"]
			grab_normal = gd["normal"]

	# Wichtig: Pullup sofort starten wenn du in der Luft Space drückst
	# Ich nutze hier Hold oder Tap damit es zuverlässig ist
	var jumpPressedNow: bool = jumpTapped or Input.is_key_pressed(jump_Keybind)

	# Optional: nur greifen wenn du nicht mehr stark nach oben fliegst
	# Das verhindert zufälliges Greifen direkt beim Absprung
	if can_grab and jumpPressedNow and velocity.y <= 0.5:
		_start_pullup(grab_point, grab_normal)

	# Climb Pullup Ablauf
	if isClimbing:
		isDashing = false

		if isPullingUp:
			pullup_t += delta

			if pullup_stage == 0:
				var a0: float = clampf(pullup_t / max(snap_time, 0.01), 0.0, 1.0)
				a0 = a0 * a0 * (3.0 - 2.0 * a0)
				global_position = pullup_from.lerp(pullup_mid, a0)
				velocity = Vector3.ZERO

				if pullup_t >= snap_time:
					pullup_stage = 1
					pullup_t = 0.0

			else:
				var a1: float = clampf(pullup_t / max(pullup_time, 0.01), 0.0, 1.0)
				a1 = a1 * a1 * (3.0 - 2.0 * a1)
				global_position = pullup_mid.lerp(pullup_to, a1)
				velocity = Vector3.ZERO

				if pullup_t >= pullup_time:
					isPullingUp = false
					isClimbing = false
					velocity.y = 2.0

		else:
			# Wenn du irgendwann echtes Klettern willst kannst du das hier nutzen
			velocity.x = 0.0
			velocity.z = 0.0

			var v := Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
			velocity.y = v * climb_speed

			if Input.is_key_pressed(dash_Keybind) or Input.is_key_pressed(run_Keybind):
				isClimbing = false
				isPullingUp = false

	else:
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
		if jumpTapped and is_on_floor():
			velocity.y = jump_Velocity

	# Move
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down");
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized();

	if isClimbing:
		pass
	elif isDashing:
		var dash_dir: Vector3 = -player.global_transform.basis.z.normalized();
		var dash_speed: float = (speed + dash_Force);
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

	jumpTapped = false


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.screen_relative.x * camera_sensitivity;
		cameraGimbal.rotation_degrees.x -= event.screen_relative.y * camera_sensitivity;
		cameraGimbal.rotation_degrees.x = clamp(cameraGimbal.rotation_degrees.x, -30.0, 20.0);

	if event is InputEventKey:
		if event.keycode == jump_Keybind and event.pressed:
			jumpTapped = true

		if event.keycode == run_Keybind:
			if event.pressed:
				isRunning = true;
			else:
				isRunning = false;

		if event.keycode == dash_Keybind:
			if event.pressed and canDash and not isClimbing and not isPullingUp:
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

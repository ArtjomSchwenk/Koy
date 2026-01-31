extends CharacterBody3D

@onready var gm: GameManager = GameManager
@onready var player: CharacterBody3D = $"."
#Aniamtion
@onready var anim: AnimationPlayer = $Model/AnimationPlayer
#Soundeffect schritte
@onready var footstep: AudioStreamPlayer3D = $FootstepPlayer


@export_group("Movement")
@export var speed: float = 4.0
@export var runModif: float = 5.0
@export var isRunning: bool = false
@export var jump_Velocity: float = 15.0

@export var gravity_force: float = 30.0
@export var fall_multiplier: float = 1.8
@export var low_jump_multiplier: float = 2.2

@export_group("Climb Pullup")
@export var isClimbing: bool = false
@export var snap_back_offset: float = 0.45
@export var snap_down_offset: float = 0.65

@export var pullup_time: float = 1.0
@export var pullup_up: float = 0.6
@export var pullup_forward: float = 0.6

# Das ist dein halber Kopf Bonus
@export var pullup_extra_up: float = 0.25

@export var snap_time: float = 0.08
@export var pullup_end_down_push: float = 2.0
@export var pullup_lock_input: bool = true

var isPullingUp: bool = false
var pullup_t: float = 0.0
var pullup_from: Vector3 = Vector3.ZERO
var pullup_mid: Vector3 = Vector3.ZERO
var pullup_to: Vector3 = Vector3.ZERO
var pullup_stage: int = 0
var pullup_wall_normal: Vector3 = Vector3.ZERO

@onready var ray_chest_mid: RayCast3D = $climbChecksChest/ray_chest_mid
@onready var ray_chest_left: RayCast3D = $climbChecksChest/ray_chest_left
@onready var ray_chest_right: RayCast3D = $climbChecksChest/ray_chest_right

@onready var ray_head_mid: RayCast3D = $climbCheckHead/ray_head_mid
@onready var ray_head_left: RayCast3D = $climbCheckHead/ray_head_left
@onready var ray_head_right: RayCast3D = $climbCheckHead/ray_head_right

var direction: Vector3 = Vector3.ZERO

@export_group("Settings")
@export var camera_sensitivity: float = 0.35
@export var isPaused: bool = false
@export var interact_Keybind: int = KEY_E
@export var run_Keybind: int = KEY_SHIFT
@export var jump_Keybind: int = KEY_SPACE

@onready var cameraGimbal: Node3D = get_node("cameraGimbal")
@onready var raycast: RayCast3D = get_node("cameraGimbal/head/RayCast3D")
var canInteract: bool = false

var jumpTapped: bool = false

const ANIM_PULLUP: String = "general/pullup"
const ANIM_IDLE_GROUND: String = "general/idle"
const ANIM_WALK: String = "walking"
const ANIM_JUMP_IDLE: String = "Jump_Idle"
const ANIM_RUN: String = "Running_A"

@export_group("Debug")
@export var debug_fly_enabled: bool = true
@export var debug_fly_speed: float = 12.0
@export var debug_fly_toggle_key: int = KEY_T

var debug_flying: bool = false

func _ready() -> void:
	GameManager.register_player(self)
	raycast.add_exception(self)

func play_anim(name: String) -> void:
	if anim == null:
		return
	if anim.current_animation == name:
		return
	if anim.has_animation(name):
		anim.play(name)

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

	pullup_wall_normal = grab_normal.normalized()

	velocity = Vector3.ZERO
	pullup_from = global_position

	pullup_mid = grab_point + pullup_wall_normal * snap_back_offset + Vector3(0.0, -snap_down_offset, 0.0)

	# pullup_up + pullup_extra_up sorgt fuer den halben Kopf mehr
	var up_amount := pullup_up + pullup_extra_up
	pullup_to = pullup_mid + Vector3.UP * up_amount + (-pullup_wall_normal) * pullup_forward

	play_anim(ANIM_PULLUP)

func _ease(a: float) -> float:
	return a * a * (3.0 - 2.0 * a)

func _move_towards(target: Vector3, delta: float) -> void:
	var step: Vector3 = target - global_position
	velocity = step / max(delta, 0.001)
	move_and_slide()
	velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	isRunning = Input.is_key_pressed(run_Keybind)

	# Interact Check
	if raycast.is_colliding():
		var target = raycast.get_collider()
		if target is Interactable:
			canInteract = true
			gm.interactionAvailable.emit(target.prompt_message)
	else:
		canInteract = false
		gm.interactionAvailable.emit("")

	# Debug Fly Mode (T toggle, F up, G down)
	if debug_fly_enabled and debug_flying:
		var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var planar := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

		var y := 0.0
		if Input.is_key_pressed(KEY_F):
			y += 1.0
		if Input.is_key_pressed(KEY_G):
			y -= 1.0

		velocity = Vector3(planar.x, y, planar.z) * debug_fly_speed
		move_and_slide()

		jumpTapped = false
		return

	var can_grab: bool = false
	var grab_point: Vector3 = Vector3.ZERO
	var grab_normal: Vector3 = Vector3.ZERO

	if not is_on_floor() and not isClimbing and not isPullingUp:
		var gd := _get_grab_data()
		if gd["ok"]:
			can_grab = true
			grab_point = gd["point"]
			grab_normal = gd["normal"]

	var jumpPressedNow: bool = jumpTapped or Input.is_key_pressed(jump_Keybind)

	if can_grab and jumpPressedNow and velocity.y <= 0.5:
		_start_pullup(grab_point, grab_normal)

	if isClimbing and isPullingUp:
		pullup_t += delta

		if pullup_stage == 0:
			var a0: float = clampf(pullup_t / max(snap_time, 0.01), 0.0, 1.0)
			a0 = _ease(a0)
			var target0: Vector3 = pullup_from.lerp(pullup_mid, a0)
			_move_towards(target0, delta)

			if pullup_t >= snap_time:
				pullup_stage = 1
				pullup_t = 0.0
		else:
			var a1: float = clampf(pullup_t / max(pullup_time, 0.01), 0.0, 1.0)
			a1 = _ease(a1)
			var target1: Vector3 = pullup_mid.lerp(pullup_to, a1)
			_move_towards(target1, delta)

			if pullup_t >= pullup_time:
				isPullingUp = false
				isClimbing = false

				velocity = Vector3.DOWN * pullup_end_down_push
				move_and_slide()
				velocity = Vector3.ZERO

	else:
		if not is_on_floor():
			velocity.y -= gravity_force * delta

			if velocity.y < 0.0:
				velocity.y -= gravity_force * (fall_multiplier - 1.0) * delta
			elif velocity.y > 0.0 and not Input.is_key_pressed(jump_Keybind):
				velocity.y -= gravity_force * (low_jump_multiplier - 1.0) * delta
		else:
			if velocity.y < 0.0:
				velocity.y = 0.0

		if jumpTapped and is_on_floor():
			velocity.y = jump_Velocity

	var input_dir2 := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	direction = (transform.basis * Vector3(input_dir2.x, 0, input_dir2.y)).normalized()

	var allow_move: bool = true
	if pullup_lock_input and (isClimbing or isPullingUp):
		allow_move = false

	if not allow_move:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		if isClimbing:
			velocity.x = 0.0
			velocity.z = 0.0
		elif direction:
			velocity.x = direction.x * (speed + int(isRunning) * runModif)
			velocity.z = direction.z * (speed + int(isRunning) * runModif)
		else:
			velocity.x = 0.0
			velocity.z = 0.0

		move_and_slide()

	if isPullingUp or isClimbing:
		play_anim(ANIM_PULLUP)
	elif not is_on_floor():
		play_anim(ANIM_JUMP_IDLE)
	else:
		var moving: bool = (absf(velocity.x) > 0.1) or (absf(velocity.z) > 0.1)
		if moving:
			if isRunning:
				play_anim(ANIM_RUN)
			else:
				play_anim(ANIM_WALK)
		else:
			play_anim(ANIM_IDLE_GROUND)

	jumpTapped = false

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.screen_relative.x * camera_sensitivity
		cameraGimbal.rotation_degrees.x -= event.screen_relative.y * camera_sensitivity
		cameraGimbal.rotation_degrees.x = clamp(cameraGimbal.rotation_degrees.x, -30.0, 20.0)
		

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			GameManager.respawn_at_checkpoint()



		if event.keycode == jump_Keybind and event.pressed:
			jumpTapped = true

		if event.keycode == run_Keybind:
			isRunning = event.pressed

		if event.keycode == debug_fly_toggle_key and event.pressed:
			debug_flying = !debug_flying

		if event.keycode == KEY_ESCAPE:
			pauseGame()

		if event.is_action_pressed("interact"):
			gm.interactionTrigger.emit(raycast.get_collider())

func pauseGame():
	isPaused = true
	gm.setGameState(gm.GAME_STATE.PAUSE)
	
func play_footstep() -> void:
	if footstep == null:
		return
	if not is_on_floor():
		return
	if isClimbing or isPullingUp:
		return
	footstep.play()

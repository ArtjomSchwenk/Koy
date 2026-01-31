extends Node

const MAIN_MENU: PackedScene = preload("res://Assets/Scenes/Menus/MainMenu.tscn")
const GAME_WORLD: String = "res://Assets/Scenes/terrain_data/welt.tscn"
const PAUSE_SCREEN: PackedScene = preload("res://Assets/Scenes/Menus/pauseScreen.tscn")
const SETTINGS_SCREEN: PackedScene = preload("res://Assets/Scenes/Menus/settingsMenu.tscn")
const GAME_OVERLAY: PackedScene = preload("uid://d30pp2svsgjo7")
const SAVE_PATH := "user://savegame.json"

var pauseScreen: Node = null
var settingsScreen: Node = null
var settingsScreenBool: bool = false
var fullscreenBool: bool = true

var isLoading: bool = false
var load_progress: Array = []
var load_Status: int = 0

var gameOverlay: Control = null

# Save Daten
var last_checkpoint_pos: Vector3 = Vector3.ZERO
var has_checkpoint: bool = false

var start_pos: Vector3 = Vector3.ZERO
var has_start_pos: bool = false

# Laufzeit Referenzen
var player_ref: CharacterBody3D = null
var checkpoints: Array = []

# Welt scene speichern
var world_scene: PackedScene = null

# Checkpoint Array ID
var collected_checkpoint_ids: Array[String] = []



signal loadingDone
signal settingsTrigger
signal resolutionChange
signal fullscreenTrigger
signal interactionTrigger
signal interactionAvailable

enum GAME_STATE { QUIT = -1, START = 0, PLAY = 1, LOAD = 2, PAUSE = 3, CONTINUE = 4 }
static var currentGameState: int
static var current_Scene: Node = null

func _ready() -> void:
	_setup()
	load_run() # Save beim Start laden
	ResourceLoader.load_threaded_request(GAME_WORLD)

func _process(delta: float) -> void:
	if isLoading:
		load_Status = ResourceLoader.load_threaded_get_status(GAME_WORLD, load_progress)
		if load_Status == ResourceLoader.THREAD_LOAD_LOADED:
			isLoading = false
			world_scene = ResourceLoader.load_threaded_get(GAME_WORLD)
			loadingDone.emit()

func _setup() -> void:
	pauseScreen = PAUSE_SCREEN.instantiate()
	pauseScreen.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pauseScreen)
	pauseScreen.hide()

	settingsScreen = SETTINGS_SCREEN.instantiate()
	settingsScreen.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(settingsScreen)
	settingsScreen.hide()

	gameOverlay = GAME_OVERLAY.instantiate()
	add_child(gameOverlay)
	gameOverlay.hide()

	settingsTrigger.connect(_on_settings_trigger)
	resolutionChange.connect(_on_resolution_change)
	fullscreenTrigger.connect(_on_fullscreen_trigger)
	interactionAvailable.connect(_on_interaction_available)
	interactionTrigger.connect(_on_interaction_trigger)

	setGameState(GAME_STATE.START)

func _on_settings_trigger() -> void:
	if not settingsScreenBool:
		showSettingsMenu()
		settingsScreenBool = true
	else:
		hideSettingsMenu()
		settingsScreenBool = false

func _on_resolution_change(res: Vector2i) -> void:
	var window: Window = get_window()
	window.size = Vector2i(res)
	window.move_to_center()

func _on_fullscreen_trigger() -> void:
	fullscreenBool = !fullscreenBool
	changeDisplayMode()

func _on_interaction_available(args: String) -> void:
	showAvailableInteraction(args)

func _on_interaction_trigger(args: Interactable) -> void:
	if args:
		args.triggerInteraction.emit()

func goto_scene(scene_Resource: PackedScene) -> void:
	if scene_Resource == null:
		push_error("goto_scene called with null scene")
		return
	call_deferred("_deferred_goto_scene", scene_Resource)


func _deferred_goto_scene(scene_Resource: PackedScene) -> void:
	if current_Scene:
		current_Scene.free()
	var new_Scene = scene_Resource.instantiate()
	get_tree().root.add_child(new_Scene)
	current_Scene = new_Scene

func setGameState(State: GAME_STATE) -> void:
	print("State changed to: " + str(State))
	currentGameState = State
	changeGameState()

func changeGameState() -> void:
	match currentGameState:
		GAME_STATE.START:
			loadMainMenu()
		GAME_STATE.PLAY:
			loadGame()
		GAME_STATE.LOAD:
			loadLoadingScreen()
		GAME_STATE.PAUSE:
			pauseGame()
		GAME_STATE.CONTINUE:
			unpauseGame()
		GAME_STATE.QUIT:
			quitGame()

func loadMainMenu() -> void:
	get_tree().paused = false
	pauseScreen.hide()
	settingsScreen.hide()
	settingsScreenBool = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	goto_scene(MAIN_MENU)

func loadGame() -> void:
	if world_scene == null:
		isLoading = true
		await loadingDone

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	goto_scene(world_scene)


	var game: PackedScene = ResourceLoader.load_threaded_get(GAME_WORLD)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	goto_scene(game)

func loadLoadingScreen() -> void:
	pass

func pauseGame() -> void:
	pauseScreen.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true

func unpauseGame() -> void:
	pauseScreen.hide()
	settingsScreen.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

func quitGame() -> void:
	save_run()
	get_tree().quit()

func showSettingsMenu() -> void:
	pauseScreen.hide()
	settingsScreen.show()

func hideSettingsMenu() -> void:
	pauseScreen.show()
	settingsScreen.hide()

func changeDisplayMode() -> void:
	var window: Window = get_window()
	if fullscreenBool:
		window.mode = window.MODE_FULLSCREEN
	else:
		window.mode = window.MODE_WINDOWED

func showAvailableInteraction(args: String) -> void:
	var promptLabel: Label = $Prompt
	if args == "":
		gameOverlay.hide()
	else:
		promptLabel.text = "'E' to " + args
		gameOverlay.show()

# -------------------------
# Checkpoints
# -------------------------

func set_checkpoint(pos: Vector3) -> void:
	last_checkpoint_pos = pos
	has_checkpoint = true
	save_run()
	print("Checkpoint set: ", pos)

func register_player(p: CharacterBody3D) -> void:
	player_ref = p

	# Start speichern
	if not has_start_pos:
		start_pos = p.global_position
		has_start_pos = true

	# Falls noch nie ein Checkpoint existiert: Start ist der erste
	if not has_checkpoint:
		last_checkpoint_pos = start_pos
		has_checkpoint = true

	# Wenn Save geladen wurde: spawn am letzten Checkpoint
	player_ref.global_position = last_checkpoint_pos
	player_ref.velocity = Vector3.ZERO

	print("Player registered: ", p.name)

func respawn_at_checkpoint() -> void:
	if not has_checkpoint:
		print("No checkpoint yet")
		return
	if player_ref == null:
		print("No player registered")
		return

	player_ref.global_position = last_checkpoint_pos
	player_ref.velocity = Vector3.ZERO
	print("Respawned at checkpoint: ", last_checkpoint_pos)

func restart_run() -> void:
	if player_ref == null or not has_start_pos:
		print("No start pos")
		return

	# Checkpoints wieder erscheinen lassen
	reset_all_checkpoints()

	# Fortschritt löschen
	collected_checkpoint_ids.clear()

	# letzter Checkpoint zurück auf Start
	last_checkpoint_pos = start_pos
	has_checkpoint = true

	# Player zurück
	player_ref.global_position = start_pos
	player_ref.velocity = Vector3.ZERO

	save_run()
	print("Restarted at start: ", start_pos)


func register_checkpoint(cp: Node) -> void:
	if not checkpoints.has(cp):
		checkpoints.append(cp)

func reset_all_checkpoints() -> void:
	for cp in checkpoints:
		if cp and cp.has_method("reset_checkpoint"):
			cp.reset_checkpoint()

# -------------------------
# Save Load
# -------------------------

func save_run() -> void:
	var data := {
		"has_checkpoint": has_checkpoint,
		"checkpoint_pos": [last_checkpoint_pos.x, last_checkpoint_pos.y, last_checkpoint_pos.z],
		"has_start_pos": has_start_pos,
		"start_pos": [start_pos.x, start_pos.y, start_pos.z],
		"collected_ids": collected_checkpoint_ids
	}

	var json := JSON.stringify(data)
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		print("Save failed")
		return
	f.store_string(json)
	f.close()
	print("Saved")


func load_run() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save found")
		return

	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		print("Load failed")
		return

	var text := f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		print("Save corrupted")
		return

	has_checkpoint = parsed.get("has_checkpoint", false)

	var cp: Array = parsed.get("checkpoint_pos", [])
	if cp.size() == 3:
		last_checkpoint_pos = Vector3(float(cp[0]), float(cp[1]), float(cp[2]))

	has_start_pos = parsed.get("has_start_pos", false)
	var sp: Array = parsed.get("start_pos", [])
	if sp.size() == 3:
		start_pos = Vector3(float(sp[0]), float(sp[1]), float(sp[2]))

	# HIER rein kommt das:
	var ids: Array = parsed.get("collected_ids", [])
	collected_checkpoint_ids.clear()
	for v in ids:
		collected_checkpoint_ids.append(str(v))

	print("Loaded. has_checkpoint=", has_checkpoint, " pos=", last_checkpoint_pos, " collected=", collected_checkpoint_ids.size())


func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("Save deleted")

func mark_checkpoint_collected(id: String) -> void:
	if id == "":
		return
	if not collected_checkpoint_ids.has(id):
		collected_checkpoint_ids.append(id)
		save_run()

func is_checkpoint_collected(id: String) -> bool:
	if id == "":
		return false
	return collected_checkpoint_ids.has(id)

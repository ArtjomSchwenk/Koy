extends Node

const MAIN_MENU: PackedScene = preload("res://Assets/Scenes/Menus/MainMenu.tscn")
##const LOAD_SCREEN = preload("res://Assets/Scenes/Game/loading_screen.tscn") ## Not Needed for current scope of game :D
const GAME_WORLD: NodePath = "res://Assets/Scenes/terrain_data/welt.tscn"
const PAUSE_SCREEN: PackedScene = preload("res://Assets/Scenes/Menus/pauseScreen.tscn")
const SETTINGS_SCREEN: PackedScene = preload("res://Assets/Scenes/Menus/settingsMenu.tscn")
const GAME_OVERLAY: PackedScene = preload("uid://d30pp2svsgjo7");

var pauseScreen: Node = null;
var settingsScreen: Node = null;
var settingsScreenBool: bool = false;
var fullscreenBool: bool = true;
var isLoading: bool;
var gameOverlay: Control = null;
var load_progress = [];
var load_Status: int = 0;
var last_checkpoint_pos: Vector3 = Vector3.ZERO
var has_checkpoint: bool = false
var player_ref: CharacterBody3D = null
var start_pos: Vector3 = Vector3.ZERO
var has_start_pos: bool = false
var checkpoints: Array = []




signal loadingDone
signal settingsTrigger
signal resolutionChange
signal fullscreenTrigger
signal interactionTrigger
signal interactionAvailable

enum GAME_STATE {QUIT = -1, START = 0, PLAY = 1, LOAD = 2, PAUSE = 3, CONTINUE = 4};
static var currentGameState: int;
static var current_Scene: Node = null;

func _ready() -> void:
	_setup();
	ResourceLoader.load_threaded_request(GAME_WORLD);

	

func _process(delta: float) -> void:
	if isLoading:
		load_Status = ResourceLoader.load_threaded_get_status(GAME_WORLD, load_progress);
		if load_Status == ResourceLoader.THREAD_LOAD_LOADED:
			isLoading = false;
			loadingDone.emit();
	

func _setup():
	pauseScreen = PAUSE_SCREEN.instantiate();
	pauseScreen.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pauseScreen);
	pauseScreen.hide();
	settingsScreen = SETTINGS_SCREEN.instantiate();
	settingsScreen.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(settingsScreen);
	settingsScreen.hide();
	setGameState(GAME_STATE.START);
	
	gameOverlay = GAME_OVERLAY.instantiate();
	add_child(gameOverlay);
	gameOverlay.hide();
	
	settingsTrigger.connect(_on_settings_trigger);
	resolutionChange.connect(_on_resolution_change);
	fullscreenTrigger.connect(_on_fullscreen_trigger);
	interactionAvailable.connect(_on_interaction_available);
	interactionTrigger.connect(_on_interaction_trigger);

func _on_settings_trigger():
	if !settingsScreenBool:
		showSettingsMenu();
		settingsScreenBool = true;
	else:
		hideSettingsMenu();
		settingsScreenBool = false;
func _on_resolution_change(res: Vector2i):
	var window: Window = get_window();
	window.size = Vector2i(res);
	window.move_to_center();
	
func _on_fullscreen_trigger():
	fullscreenBool = !fullscreenBool;
	changeDisplayMode();
		
func _on_interaction_available(args: String) -> void:
	showAvailableInteraction(args);

func _on_interaction_trigger(args: Interactable) -> void:
	if args:
		args.triggerInteraction.emit()

func goto_scene(scene_Resource):
	call_deferred("_deferred_goto_scene", scene_Resource)

func _deferred_goto_scene(scene_Resource: PackedScene):
	if current_Scene:
		current_Scene.free()
	var new_Scene = scene_Resource.instantiate()
	get_tree().root.add_child(new_Scene)
	current_Scene = new_Scene
	
func setGameState(State: GAME_STATE):
	print("State changed to: " + str(State));
	self.currentGameState = State;
	changeGameState();
	
func changeGameState():
	match currentGameState: 
		##Main Menu at start of Game
		GAME_STATE.START: 
			loadMainMenu();
		GAME_STATE.PLAY: 
			loadGame();
		GAME_STATE.LOAD: 
			loadLoadingScreen();
		GAME_STATE.PAUSE: 
			pauseGame();
		GAME_STATE.CONTINUE: 
			unpauseGame();
		GAME_STATE.QUIT: 
			quitGame();
			
func loadMainMenu():
	# wichtig: pausieren aufheben sonst bleibt das menu eingefroren
	get_tree().paused = false

	pauseScreen.hide()
	settingsScreen.hide()
	settingsScreenBool = false

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# optional: wenn du den Lade-Flow nutzen willst
	isLoading = true

	goto_scene(MAIN_MENU)

	
		
func loadGame():
	if isLoading:
		print("Waiting");
		await loadingDone;
	var game: PackedScene = ResourceLoader.load_threaded_get(GAME_WORLD);
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
	goto_scene(game);
	
func loadLoadingScreen(): ##Not necessary for current scope tbh
	pass

func pauseGame():
	pauseScreen.show();
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
	current_Scene.get_tree().paused = true;
	

func unpauseGame():
	pauseScreen.hide();
	settingsScreen.hide();
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
	current_Scene.get_tree().paused = false;
	

func quitGame():
	get_tree().quit();
	
func showSettingsMenu():
	pauseScreen.hide();
	settingsScreen.show();
	
func hideSettingsMenu():
	pauseScreen.show();
	settingsScreen.hide();
	
func changeDisplayMode():
	var window: Window = get_window();
	if fullscreenBool:
		window.mode = window.MODE_FULLSCREEN;
		print("window mode fullscreen");
	else:
		window.mode = window.MODE_WINDOWED;
		print("window mode windowed");

func showAvailableInteraction(args: String):
	var promptLabel: Label = $Prompt
	if args == "":
		gameOverlay.hide();
	else:
		promptLabel.text = "'E' to " + args;
		gameOverlay.show()
		
	## Checkpoint	
func set_checkpoint(pos: Vector3) -> void:
	last_checkpoint_pos = pos
	has_checkpoint = true
	print("Checkpoint set: ", pos)
	
func register_player(p: CharacterBody3D) -> void:
	player_ref = p

	if not has_start_pos:
		start_pos = p.global_position
		has_start_pos = true

	# Startpunkt als erster Checkpoint
	if not has_checkpoint:
		last_checkpoint_pos = start_pos
		has_checkpoint = true

	print("Player registered: ", p.name)

func restart_run() -> void:
	if player_ref == null or not has_start_pos:
		print("No start pos")
		return

	# Checkpoints wieder erscheinen lassen
	reset_all_checkpoints()

	# Gesammelte Checkpoints löschen (Fortschritt reset)
	last_checkpoint_pos = start_pos
	has_checkpoint = true

	# Player zurück
	player_ref.global_position = start_pos
	player_ref.velocity = Vector3.ZERO

	print("Restarted at start: ", start_pos)


	
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
	
func register_checkpoint(cp: Node) -> void:
	if not checkpoints.has(cp):
		checkpoints.append(cp)

func reset_all_checkpoints() -> void:
	for cp in checkpoints:
		if cp and cp.has_method("reset_checkpoint"):
			cp.reset_checkpoint()

extends Node

const MAIN_MENU = preload("res://Assets/Scenes/Menus/MainMenu.tscn")
##const LOAD_SCREEN = preload("res://Assets/Scenes/Game/loading_screen.tscn") ## Not Needed for current scope of game :D
const GAME_WORLD: NodePath = "res://Assets/Scenes/terrain_data/welt.tscn"

var isLoading: bool;
var load_progress = [];
var load_Status: int = 0;
signal loadingDone

enum GAME_STATE {QUIT = -1, START = 0, PLAY = 1, LOAD = 2, PAUSE = 3, CONTINUE = 4};
static var currentGameState;
static var current_Scene = null

func _ready() -> void:
	setGameState(GAME_STATE.START);
	ResourceLoader.load_threaded_request(GAME_WORLD)
	

func _process(delta: float) -> void:
	if isLoading:
		load_Status = ResourceLoader.load_threaded_get_status(GAME_WORLD, load_progress);
		if load_Status == ResourceLoader.THREAD_LOAD_LOADED:
			isLoading = false;
			loadingDone.emit();
	
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
		0: ##Main Menu at start of Game
			loadMainMenu();
		1: 
			loadGame();
		2: 
			loadLoadingScreen();
		3: 
			pauseGame();
		4: 
			unpauseGame();
		5: 
			quitGame();
			
func loadMainMenu():
	isLoading = true;

	goto_scene(MAIN_MENU)
	
func loadGame():
	if isLoading:
		print("Waiting");
		await loadingDone;
	var game: PackedScene = ResourceLoader.load_threaded_get(GAME_WORLD);
	goto_scene(game);
	
func loadLoadingScreen(): ##Not necessary for current scope tbh
	pass

func pauseGame():
	pass

func unpauseGame():
	pass

func quitGame():
	get_tree().quit();

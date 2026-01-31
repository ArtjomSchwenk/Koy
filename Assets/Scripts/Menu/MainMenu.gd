extends CanvasLayer



@onready var play_Button: Button =  $Menu/MarginContainer/VBoxContainer/PlayButton;
@onready var quit_Button: Button= $Menu/MarginContainer/VBoxContainer/QuitButton;
@onready var cameraGimbal_Node: Node3D = $Background/SubViewportContainer/SubViewport/CameraGimbal;
@onready var gm: GameManager = GameManager;

@export var radius: float = 1.0;
@export var angle: float = 0.0;
@export var speed: float = 0.0001;

func _ready() -> void:
	MusicManager.play_menu()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	cameraCircularMotion()
	
	## Cool effect :D
func cameraCircularMotion():
	var x_pos: float = cos(angle);
	var y_pos: float = sin(angle);
	cameraGimbal_Node.position.y += speed * (radius * y_pos);
	cameraGimbal_Node.position.x += speed * (radius * x_pos);
	
	angle += 1 * speed;
	
func _on_play_button_pressed() -> void:
	$UIClickPlayer.play()
	gm.setGameState(gm.GAME_STATE.PLAY);

func _on_quit_button_pressed() -> void:
	$UIClickPlayer.play()
	gm.setGameState(gm.GAME_STATE.QUIT);

func _play_hover() -> void:
	if $UIHoverPlayer.playing:
		return
	$UIHoverPlayer.play()

func _on_play_button_mouse_entered() -> void:
	_play_hover()

func _on_quit_button_mouse_entered() -> void:
	_play_hover()

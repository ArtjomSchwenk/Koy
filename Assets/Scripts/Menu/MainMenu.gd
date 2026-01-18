extends CanvasLayer


@onready var play_Button: Button =  $Menu/MarginContainer/VBoxContainer/PlayButton;
@onready var settings_Button: Button = $Menu/MarginContainer/VBoxContainer/SettingsButton;
@onready var quit_Button: Button= $Menu/MarginContainer/VBoxContainer/QuitButton;
@onready var camera_Node: Camera3D = $Background/SubViewportContainer/SubViewport/Camera3D;
@onready var background3D_Node: Node3D = $Background/gebeude_1;

@export var radius: float = 5.0;
@export var angle: float = 0.0;
@export var speed: float = 5.0;
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func cameraCircularMotion():
	var x_pos: float = cos(angle);
	var y_pos: float = sin(angle);

	camera_Node.position.y = radius * y_pos;
	
	

extends Control

@onready var gm: GameManager = GameManager


func _ready() -> void:
	# Damit UI + Audio auch im Pause Zustand reagiert
	process_mode = Node.PROCESS_MODE_ALWAYS
	$UIClickPlayer.process_mode = Node.PROCESS_MODE_ALWAYS
	$UIHoverPlayer.process_mode = Node.PROCESS_MODE_ALWAYS

func _play_click() -> void:
	$UIClickPlayer.play()

func _play_hover() -> void:
	if $UIHoverPlayer.playing:
		return
	$UIHoverPlayer.play()

func _on_continue_button_pressed() -> void:
	_play_click()
	gm.setGameState(gm.GAME_STATE.CONTINUE)

func _on_settings_button_pressed() -> void:
	_play_click()
	gm.settingsTrigger.emit()

func _on_quit_button_pressed() -> void:
	_play_click()
	gm.setGameState(gm.GAME_STATE.START) # zurück ins Main Menu


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		gm.setGameState(gm.GAME_STATE.CONTINUE)

func _on_continue_button_mouse_entered() -> void:
	_play_hover()

func _on_settings_button_mouse_entered() -> void:
	_play_hover()

func _on_quit_button_mouse_entered() -> void:
	_play_hover()

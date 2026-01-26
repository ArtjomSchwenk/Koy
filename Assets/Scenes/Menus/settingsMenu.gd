extends Control


var gm: GameManager = GameManager;

func _on_continue_button_pressed() -> void:
	gm.setGameState(gm.GAME_STATE.CONTINUE);
	
func _on_settings_button_pressed() -> void:
	gm.settingsTrigger.emit();
	
func _on_quit_button_pressed() -> void:
	gm.setGameState(gm.GAME_STATE.QUIT);
	
func _unhandled_key_input(event: InputEvent) -> void:
	if event.keycode == KEY_ESCAPE:
		gm.setGameState(gm.GAME_STATE.CONTINUE);

extends Control


var gm: GameManager = GameManager;
@onready var volume_slider: HSlider = $BoxContainer/volume

func _ready() -> void:
	var master := 0
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master))

func _unhandled_input(event: InputEvent) -> void:
	if self.is_visible_in_tree():
		if event is InputEventKey:
			if event.keycode == KEY_ESCAPE:
				gm.setGameState(gm.GAME_STATE.CONTINUE);
	
func _on_continue_button_pressed() -> void:
	gm.setGameState(gm.GAME_STATE.CONTINUE);

func _on_volume_value_changed(value: float) -> void:
	var master := 0
	AudioServer.set_bus_volume_db(master, linear_to_db(max(value, 0.001)))

func _on_mute_button_toggled(toggled_on: bool) -> void:
	var master := 0
	AudioServer.set_bus_mute(master, toggled_on)

	
func _on_option_button_item_selected(index: int) -> void:
	var res: Vector2i;
	match index:
		0: res = Vector2i(1920,1080);
		1: res = Vector2i(1280, 800);
	gm.resolutionChange.emit(res);
	
func _on_back_button_pressed() -> void:
	gm.settingsTrigger.emit();

func _on_fullscreen_toggle_toggled(toggled_on: bool) -> void:
	gm.fullscreenTrigger.emit();

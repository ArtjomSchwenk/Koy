extends Node

var player: AudioStreamPlayer

func _enter_tree() -> void:
	player = AudioStreamPlayer.new()
	add_child(player)
	player.bus = "Music"
	player.volume_db = -6.0

func _fade_to(db: float, duration: float = 0.4) -> void:
	var t := create_tween()
	t.tween_property(player, "volume_db", db, duration)

func _play_with_fade(stream: AudioStream) -> void:
	if player.playing:
		_fade_to(-40.0, 0.25)
		await get_tree().create_timer(0.25).timeout

	player.stream = stream
	player.volume_db = -40.0
	player.play()
	_fade_to(-6.0, 0.35)

func play_menu() -> void:
	await _play_with_fade(preload("res://Assets/Scenes/Audio/menu.ogg"))

func play_game_low() -> void:
	await _play_with_fade(preload("res://Assets/Scenes/Audio/game_low.ogg"))

func play_game_high() -> void:
	await _play_with_fade(preload("res://Assets/Scenes/Audio/game_high.ogg"))

extends Node3D

@export var height_threshold := 150.0
@export var hysteresis := 5.0

var in_high := false

func _ready() -> void:
	MusicManager.play_game_low()

func _process(_delta: float) -> void:
	# Spieler finden (falls Name anders ist, sag mir kurz wie dein Player Node heißt)
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return

	var h := player.global_position.y

	if not in_high and h >= height_threshold:
		in_high = true
		MusicManager.play_game_high()

	if in_high and h <= height_threshold - hysteresis:
		in_high = false
		MusicManager.play_game_low()

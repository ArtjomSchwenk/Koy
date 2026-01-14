@tool
extends Node3D

@export var tile_scene: PackedScene
@export var tile_size: float = 2.0
@export var origin: Vector3 = Vector3.ZERO

@export var width: int = 30
@export var height: int = 30

# Random Look
@export var random_seed: int = 12345
@export_range(0.0, 20.0, 0.1) var random_y_degrees: float = 6.0      # leichte Drehung
@export_range(0.0, 0.5, 0.01) var random_offset: float = 0.05         # leichte Verschiebung in X/Z
@export_range(0.0, 0.2, 0.01) var random_scale: float = 0.03          # leichte Skalierung

@export var regenerate: bool:
	set(_value):
		if Engine.is_editor_hint():
			call_deferred("generate")
		regenerate = false
	get:
		return false


func _ready() -> void:
	if not Engine.is_editor_hint():
		generate()


func generate() -> void:
	if tile_scene == null:
		push_error("tile_scene ist nicht gesetzt")
		return

	_clear_generated_tiles()

	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed

	var scene_owner := get_tree().edited_scene_root
	if scene_owner == null:
		scene_owner = owner

	for z in range(height):
		for x in range(width):
			var tile := tile_scene.instantiate() as Node3D

			var pos := origin + Vector3(x * tile_size, 0.0, z * tile_size)

			# kleine Random Verschiebung (nur X/Z)
			pos.x += rng.randf_range(-random_offset, random_offset)
			pos.z += rng.randf_range(-random_offset, random_offset)
			tile.position = pos

			# kleine Random Rotation um Y
			tile.rotation.y = deg_to_rad(rng.randf_range(-random_y_degrees, random_y_degrees))

			# kleine Random Skalierung (gleichmäßig)
			var s := 1.0 + rng.randf_range(-random_scale, random_scale)
			tile.scale = Vector3(s, s, s)

			tile.set_meta("generated_tile", true)
			add_child(tile)

			if Engine.is_editor_hint() and scene_owner != null:
				tile.owner = scene_owner


func _clear_generated_tiles() -> void:
	for c in get_children():
		if c.has_meta("generated_tile"):
			if Engine.is_editor_hint():
				c.free()
			else:
				c.queue_free()

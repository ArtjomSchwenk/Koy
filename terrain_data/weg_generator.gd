@tool
extends Node3D

@export var tile_scene: PackedScene
@export var tile_size: float = 2.0
@export var origin: Vector3 = Vector3.ZERO

@export var width: int = 6
@export var height: int = 50

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

	var scene_owner := get_tree().edited_scene_root
	if scene_owner == null:
		scene_owner = owner

	for z in range(height):
		for x in range(width):
			var tile := tile_scene.instantiate()
			tile.position = origin + Vector3(x * tile_size, 0.0, z * tile_size)
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

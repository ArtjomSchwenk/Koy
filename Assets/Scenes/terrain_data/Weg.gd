extends Node3D

@export var tile_scene: PackedScene
@export var tile_size: float = 4.0
@export var origin: Vector3 = Vector3.ZERO
@export var clear_old_tiles: bool = true

# 1 bedeutet Tile setzen 0 bedeutet leer
var map := [
	[0,0,0,0,0,0,0,0,0],
	[0,1,1,1,1,1,1,0,0],
	[0,0,0,0,0,0,1,0,0],
	[0,0,0,0,0,0,1,0,0],
]

func _ready() -> void:
	generate()

func generate() -> void:
	if tile_scene == null:
		push_error("tile_scene ist nicht gesetzt")
		return

	if clear_old_tiles:
		for c in get_children():
			c.queue_free()

	for z in range(map.size()):
		for x in range(map[z].size()):
			if map[z][x] == 1:
				var tile := tile_scene.instantiate()
				tile.position = origin + Vector3(x * tile_size, 0.0, z * tile_size)
				add_child(tile)

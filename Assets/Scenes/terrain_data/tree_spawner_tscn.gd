@tool
extends Node3D

@export var cell_size: float = 10.0
@export var cell_half_extent: float = 4.0

@export var use_raycast_to_ground: bool = true
@export var ray_start_height: float = 200.0
@export var ray_length: float = 500.0
@export_flags_3d_physics var collision_mask: int = 1
@export var fallback_y: float = 0.0

@export var rng_seed: int = 12345
@export var clear_before_spawn: bool = true

@export var scale_normal: float = 1.0
@export var scale_medium: float = 1.35
@export var scale_large: float = 1.8
@export var scale_jitter: float = 0.12

@export_range(0.0, 1.0, 0.01) var w_normal: float = 0.55
@export_range(0.0, 1.0, 0.01) var w_medium: float = 0.30
@export_range(0.0, 1.0, 0.01) var w_large: float = 0.15

@export var global_scale_multiplier: float = 10

@export var group_name: StringName = &"spawned_nature"
@export var debug_logs: bool = true

# Inspector trigger
var _regenerate_internal := false
var _pending_regen := false

@export var regenerate: bool:
	get:
		return _regenerate_internal
	set(value):
		_regenerate_internal = false
		if not value:
			return
		_pending_regen = true
		if is_inside_tree():
			call_deferred("_do_regen")

var _rng := RandomNumberGenerator.new()
var _scenes: Array[PackedScene] = []

# Target cells x z
var _cells: Array[Vector2i] = [
	Vector2i(-2, 1),
	Vector2i(-2, 0),
	Vector2i(-2, -1),
	Vector2i(-1, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
	Vector2i(1, 1),
]

# Assets and per asset random count ranges
const ASSET_PATHS: Array[String] = [
	"res://Assets/Imports/More Nature/glTF/MapleTree_1.gltf",
	"res://Assets/Imports/More Nature/glTF/MapleTree_3.gltf",
	"res://Assets/Imports/More Nature/glTF/BirchTree_5.gltf",
	"res://Assets/Imports/More Nature/glTF/BirchTree_3.gltf",
	"res://Assets/Imports/More Nature/glTF/Bush_Flowers.gltf",
	"res://Assets/Imports/More Nature/glTF/BirchTree_4.gltf",
	"res://Assets/Imports/More Nature/glTF/MapleTree_5.gltf",
]

# min count per asset
const ASSET_MIN: Array[int] = [
	80,  # MapleTree_1
	80,  # MapleTree_3
	80,  # BirchTree_5
	80,  # BirchTree_3
	80,  # Bush_Flowers
	80,  # BirchTree_4
	80, # MapleTree_5
]

# max count per asset
const ASSET_MAX: Array[int] = [
	90,
	90,
	90,
	90,
	96,
	90,
	95,
]

func _enter_tree() -> void:
	_load_scenes()
	if _pending_regen:
		call_deferred("_do_regen")

func _ready() -> void:
	_load_scenes()

func _do_regen() -> void:
	if not _pending_regen:
		return
	_pending_regen = false
	spawn_assets()

func _load_scenes() -> void:
	_scenes.clear()

	for p in ASSET_PATHS:
		if not ResourceLoader.exists(p):
			push_warning("Pfad existiert nicht: %s" % p)
			continue

		var res := load(p)
		if res == null:
			push_warning("Konnte nicht laden: %s" % p)
			continue

		if res is PackedScene:
			_scenes.append(res)
		else:
			push_warning("Nicht als PackedScene importiert: %s Typ %s" % [p, res.get_class()])

	if debug_logs:
		print("TreeSpawner load scenes: ", _scenes.size())

func spawn_assets() -> void:
	if debug_logs:
		print("TreeSpawner spawn start")

	if _scenes.is_empty():
		_load_scenes()

	if _scenes.is_empty():
		push_warning("Keine Szenen geladen. Import der gltf Dateien prüfen.")
		return

	_rng.seed = rng_seed

	if clear_before_spawn:
		_clear_spawned()

	var spawned := 0
	var n := mini(_scenes.size(), ASSET_PATHS.size())

	for i in range(n):
		var min_c := ASSET_MIN[i]
		var max_c := ASSET_MAX[i]
		var count := _rng.randi_range(min_c, max_c)

		for k in range(count):
			var cell := _cells[_rng.randi_range(0, _cells.size() - 1)]
			if _spawn_specific_in_cell(i, cell):
				spawned += 1

	if debug_logs:
		print("TreeSpawner spawned: ", spawned)

func _spawn_specific_in_cell(scene_index: int, cell: Vector2i) -> bool:
	if scene_index < 0 or scene_index >= _scenes.size():
		return false

	var scene := _scenes[scene_index]
	var inst := scene.instantiate()
	if inst == null:
		return false

	var base_x := float(cell.x) * cell_size
	var base_z := float(cell.y) * cell_size

	var x := base_x + _rng.randf_range(-cell_half_extent, cell_half_extent)
	var z := base_z + _rng.randf_range(-cell_half_extent, cell_half_extent)

	var y := fallback_y
	if use_raycast_to_ground:
		y = _sample_ground_y(x, z)

	add_child(inst)
	if Engine.is_editor_hint():
		inst.owner = get_tree().edited_scene_root

	inst.global_transform.origin = Vector3(x, y, z)
	inst.rotation.y = _rng.randf_range(0.0, TAU)

	var s := _pick_scale() * global_scale_multiplier
	inst.scale = Vector3.ONE * s

	inst.add_to_group(group_name)
	return true

func _sample_ground_y(x: float, z: float) -> float:
	var space := get_world_3d().direct_space_state
	var from := Vector3(x, ray_start_height, z)
	var to := from + Vector3.DOWN * ray_length

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = collision_mask

	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return fallback_y
	return float(hit.position.y)

func _pick_scale() -> float:
	var r := _rng.randf()
	var t1 := w_normal
	var t2 := w_normal + w_medium

	var base := scale_normal
	if r < t1:
		base = scale_normal
	elif r < t2:
		base = scale_medium
	else:
		base = scale_large

	return base + _rng.randf_range(-scale_jitter, scale_jitter)

func _clear_spawned() -> void:
	for n in get_tree().get_nodes_in_group(group_name):
		if n != null and n.is_inside_tree():
			n.queue_free()

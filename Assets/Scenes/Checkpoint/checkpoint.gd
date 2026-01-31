extends Area3D

@export var one_time: bool = true

@onready var col: CollisionShape3D = $CollisionShape3D

var collected: bool = false

func _ready() -> void:
	monitoring = true
	monitorable = true
	GameManager.register_checkpoint(self)

func _on_body_entered(body: Node) -> void:
	if collected:
		return
	if body is CharacterBody3D:
		GameManager.set_checkpoint(global_position)
		if one_time:
			collect()

func collect() -> void:
	collected = true
	monitoring = false
	visible = false
	if col:
		col.disabled = true

func reset_checkpoint() -> void:
	collected = false
	monitoring = true
	visible = true
	if col:
		col.disabled = false

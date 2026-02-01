extends Node3D

@export var top_offset: Vector3 = Vector3(0, 10, 0)
@export var speed: float = 3.0

@onready var platform: AnimatableBody3D = $AnimatableBody3D
@onready var trigger: Area3D = $AnimatableBody3D/Area3D

var bottom_pos: Vector3
var top_pos: Vector3
var riders := 0

func _ready() -> void:
	bottom_pos = platform.global_position
	top_pos = bottom_pos + top_offset

	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)

	platform.sync_to_physics = true

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		riders += 1

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D:
		riders = max(0, riders - 1)

func _physics_process(delta: float) -> void:
	var target := top_pos if riders > 0 else bottom_pos
	platform.global_position = platform.global_position.move_toward(target, speed * delta)

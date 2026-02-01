extends Node3D

@export var boost: float = 22.0

@onready var area: Area3D = $Area3D

func _ready():
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body is CharacterBody3D:
		# sauber: überschreibt den Sprung direkt
		body.velocity.y = boost

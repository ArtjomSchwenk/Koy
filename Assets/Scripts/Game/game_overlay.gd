extends Control

@onready var prompt: Label = $BoxContainer/Label
signal promptSignal

func _ready() -> void:
	promptSignal.connect(_on_prompt_signal);
	
func _on_prompt_signal(args: String) -> void:
	setPrompt(args);
	
func setPrompt(str: String):
	prompt.text = str;

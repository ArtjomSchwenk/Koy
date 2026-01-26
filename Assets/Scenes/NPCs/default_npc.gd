extends Interactable

@export var dialogue_resource: DialogueResource 
func initiateDialogue():
	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")

func _on_trigger_interaction() -> void:
	initiateDialogue();

extends Interactable


@export var rotationSpeed: float = 5.0;
var isOpen: bool;
enum DOOR_STATES { IDLE = 0, OPENING = 1, CLOSING = 2}
var doorState: int;
var currentRotation: float;


func _ready() -> void:
	isOpen = false;
	setPromptMessage();
	currentRotation = rotation_degrees.y;
	
func _process(delta: float) -> void:
	match doorState:
		DOOR_STATES.IDLE:
			pass;
		DOOR_STATES.OPENING:
			currentRotation += 1 * rotationSpeed;
		DOOR_STATES.CLOSING:
			currentRotation -= 1 * rotationSpeed;
	if currentRotation <= 0.0 || currentRotation >= 120:
		doorState = DOOR_STATES.IDLE;
	rotation_degrees.y = currentRotation
func _on_trigger_interaction() -> void:
	print("door Triggered :D")
	if isOpen:
		closeDoor();
	else:
		openDoor();

func setPromptMessage():
	if isOpen:
		prompt_message = "Close";
	else:
		prompt_message = "Open";

func closeDoor():
	isOpen = false;
	doorState = DOOR_STATES.CLOSING;
	setPromptMessage();

func openDoor():
	isOpen = true;
	doorState = DOOR_STATES.OPENING;
	setPromptMessage();

	

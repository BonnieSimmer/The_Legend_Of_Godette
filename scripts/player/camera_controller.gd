extends Node3D

@export_group("Speeds")
@export var gamepad_sensitivity := Vector2(2.0, 1.0)
@export var mouse_sensitivity := 0.005

@export_group("Limits")
@export var min_limit_x := -0.8
@export var max_limit_x := -0.2

@export_group("Settings")
@export var invert_mouse_y := false
@export var invert_gamepad_y := false
@export var deadzone := 0.1

enum InputType { MOUSE, GAMEPAD }
var active_input_type := InputType.MOUSE

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	var joy_input := Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")
	
	if joy_input.length() > deadzone:
		active_input_type = InputType.GAMEPAD
		var target_rotation := joy_input * gamepad_sensitivity * delta
		
		if invert_gamepad_y:
			target_rotation.y = -target_rotation.y
			
		apply_rotation(target_rotation, false)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		active_input_type = InputType.MOUSE
		var target_rotation: Vector2 = event.relative * mouse_sensitivity
		apply_rotation(target_rotation, invert_mouse_y)

func apply_rotation(input_vector: Vector2, invert_y: bool) -> void:
	if active_input_type == InputType.GAMEPAD and Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down").length() <= deadzone:
		pass

	rotation.y -= input_vector.x
	
	if invert_y:
		rotation.x -= input_vector.y
	else:
		rotation.x -= input_vector.y
		
	rotation.x = clamp(rotation.x, min_limit_x, max_limit_x)
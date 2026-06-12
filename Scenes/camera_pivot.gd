extends Node3D

@export var mouse_sensitivity: float = 0.002
@export var min_pitch: float = -70.0 # How far you can look down
@export var max_pitch: float = 70.0  # How far you can look up

@onready var spring_arm: SpringArm3D = $SpringArm3D

func _ready() -> void:
	# Hide the mouse cursor and lock it to the center of the screen
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	# Check if the input is a mouse movement
	if event is InputEventMouseMotion:
		# Rotate the entire pivot horizontally (Yaw)
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate just the spring arm vertically (Pitch)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		
		# Clamp the vertical rotation so the camera doesn't flip upside down
		spring_arm.rotation.x = clamp(
			spring_arm.rotation.x, 
			deg_to_rad(min_pitch), 
			deg_to_rad(max_pitch)
		)

func _process(_delta: float) -> void:
	# A quick way to free your mouse cursor so you can close the game window
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

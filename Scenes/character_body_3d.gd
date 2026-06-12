extends CharacterBody3D

# @export allows you to tweak these values directly in the Godot Inspector
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.5
@export var jump_velocity: float = 4.5
@export var acceleration: float = 10.0
@export var friction: float = 200.0
@onready var camera_pivot: Node3D = $Camera_pivot
@export var rotation_speed: float = 12.0
@export var gravity_multiplier: float = 2.5
@export var dodge_speed: float = 20.0
@export var dodge_duration: float = 0.15
# Grab a reference to your visual node. 
# Right now it's your capsule mesh, but later this will be your 3D character model.
@onready var visuals: MeshInstance3D = $MeshInstance3D
# Fetch the default gravity from your Project Settings
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier

var is_dodging: bool = false
var dodge_direction: Vector3 = Vector3.ZERO
func _physics_process(delta: float) -> void:
	
	# If the character is not on the ground, pull them down.
	if not is_on_floor():
		velocity.y -= gravity * delta

	
	
	
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	
	# NEW LINE: Calculate direction based on the CAMERA'S rotation, not the player's
	var direction := (camera_pivot.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction.y = 0
	direction = direction.normalized()
	
	var current_speed := walk_speed
	var flat_velocity := Vector2(velocity.x, velocity.z)
	
	
	if Input.is_action_just_pressed("dodge") and is_on_floor() and not is_dodging:
		start_dodge(direction)
	if is_dodging:
		velocity.x = dodge_direction.x * dodge_speed
		velocity.z = dodge_direction.z * dodge_speed
	else:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity
		if Input.is_action_pressed("sprint"):
			current_speed = sprint_speed
		if flat_velocity.length() > current_speed:
			flat_velocity = flat_velocity.limit_length(current_speed)
			velocity.x = flat_velocity.x
			velocity.z = flat_velocity.y
		if direction:
			# Move towards the target speed smoothly
			velocity.x = move_toward(velocity.x, direction.x * current_speed, acceleration * delta)
			velocity.z = move_toward(velocity.z, direction.z * current_speed, acceleration * delta)
			
			var target_angle := atan2(direction.x, direction.z)
			visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, rotation_speed * delta)
		else:
			# Slide to a stop when no keys are pressed
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			velocity.z = move_toward(velocity.z, 0, friction * delta)

	
	move_and_slide()
func start_dodge(current_direction: Vector3) -> void:
	is_dodging = true
	if current_direction == Vector3.ZERO:
		dodge_direction = (camera_pivot.global_transform.basis * Vector3(0,0,1))
	else:
		dodge_direction = current_direction
		
	get_tree().create_timer(dodge_duration).timeout.connect(func(): is_dodging = false)

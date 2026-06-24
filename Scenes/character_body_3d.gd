extends CharacterBody3D

# @export allows you to tweak these values directly in the Godot Inspector
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.5
@export var jump_velocity: float = 9.5
@export var acceleration: float = 10.0
@export var friction: float = 200.0
@onready var camera_pivot: Node3D = $Camera_pivot
@export var rotation_speed: float = 12.0
@export var gravity_multiplier: float = 2.5
@export var dodge_speed: float = 20.0
@export var dodge_duration: float = 0.15
@export var joystick_sensitivity: float = 3.0
@onready var visuals: Node3D = $visuals
@onready var anim_tree: AnimationTree = $AnimationTree

@onready var stamina_bar: ProgressBar = $"../UI/stamina_bar"
@onready var anim_playback = anim_tree.get("parameters/AnimationNodeStateMachine/playback")
var current_upper_blend : float = 1.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier
var current_blend_position := Vector2.ZERO
var is_dodging: bool = false
var dodge_direction: Vector3 = Vector3.ZERO
@onready var animation_player: AnimationPlayer = $visuals/AnimationPlayer

#Stamina
@export_category("Stamina")
@export var max_stamina: float = 100.0
@export var stamina_regen_rate: float = 35.0
@export var stamina_regen_delay: float = 1.0  
@export var sprint_cost: float = 15.0         
@export var jump_cost: float = 20.0           
@export var dodge_cost: float = 30.0

#attack stuff
@export var attack_cost: float = 15.0
@onready var fist_hitbox: Area3D = $visuals/Skeleton3D/BoneAttachment3D/FistHitbox


var current_stamina = max_stamina
var stamina_delay_timer: float = 0.0

func _ready() -> void:
	floor_constant_speed = true
	floor_snap_length = 0.5
	
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current_stamina
	fist_hitbox.monitoring = false
func _process(delta: float) -> void:
	
	var camera_input := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	
	
	if camera_input.length() > 0:
		
		camera_pivot.rotation.y -= camera_input.x * joystick_sensitivity * delta
		
		camera_pivot.rotation.x -= camera_input.y * joystick_sensitivity * delta
		
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-60), deg_to_rad(45))
func _physics_process(delta: float) -> void:
	var current_leg_state = anim_playback.get_current_node()
	if not is_on_floor():
		velocity.y -= gravity * delta
	#stamina logic
	if stamina_delay_timer < stamina_regen_delay:
		stamina_delay_timer +=delta
	elif current_stamina < max_stamina:
		current_stamina = move_toward(current_stamina,max_stamina,stamina_regen_rate * delta)
	
	stamina_bar.value = current_stamina
	
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var target_blend := input_dir
	if current_leg_state == "falltoroll":
		input_dir = Vector2.ZERO
		
	target_blend = input_dir
	
	var direction := (camera_pivot.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction.y = 0
	direction = direction.normalized()
	
	var current_speed := walk_speed
	
	var flat_velocity := Vector2(velocity.x, velocity.z)
	
	
	if Input.is_action_just_pressed("dodge") and is_on_floor() and not is_dodging:
		if current_stamina >= dodge_cost:
			current_stamina -= dodge_cost
			stamina_delay_timer = 0.0
			var dash_anim_dir := input_dir
			current_upper_blend = 1.0
			if dash_anim_dir == Vector2.ZERO:
				dash_anim_dir = Vector2(0, 1)
			
			anim_tree.set("parameters/AnimationNodeStateMachine/Dash/blend_position", dash_anim_dir)
			
			anim_playback.travel("Dash")
			# --------------------------------
			
			start_dodge(direction)
	if is_dodging:
		velocity.x = dodge_direction.x * dodge_speed
		velocity.z = dodge_direction.z * dodge_speed
	else:
		#jump
		if Input.is_action_just_pressed("jump") and is_on_floor():
			if current_stamina >= jump_cost:
				current_stamina -= jump_cost
				stamina_delay_timer = 0.0
				velocity.y = jump_velocity
				
				anim_playback.travel("jumpup")
		var is_pushing_forward : bool = input_dir.y < 0.1
		if Input.is_action_pressed("sprint") and current_stamina > 0 and is_pushing_forward:
			current_speed = sprint_speed
			target_blend.y *=2.0
			current_stamina -= sprint_cost * delta
			stamina_delay_timer = 0.0
			
			if current_stamina < 0:
				current_stamina = 0
		if flat_velocity.length() > current_speed:
			flat_velocity = flat_velocity.limit_length(current_speed)
			velocity.x = flat_velocity.x
			velocity.z = flat_velocity.y
		if direction:
			
			velocity.x = move_toward(velocity.x, direction.x * current_speed, acceleration * delta)
			velocity.z = move_toward(velocity.z, direction.z * current_speed, acceleration * delta)
			
			
			visuals.rotation.y = lerp_angle(visuals.rotation.y, camera_pivot.rotation.y, rotation_speed * delta)
		else:
			
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			velocity.z = move_toward(velocity.z, 0, friction * delta)
	current_blend_position = current_blend_position.lerp(target_blend, 10.0 * delta)
	anim_tree.set("parameters/AnimationNodeStateMachine/Move/blend_position", current_blend_position)

	
	if not is_dodging and current_leg_state != "Dash":
		current_upper_blend = lerp(current_upper_blend, 0.0, 15.0 * delta)
	
	anim_tree.set("parameters/Blend2/blend_amount", current_upper_blend)
	var is_falling : bool = not is_on_floor() and velocity.y < 0.0
	anim_tree.set("parameters/AnimationNodeStateMachine/conditions/is_in_air", is_falling)
	anim_tree.set("parameters/AnimationNodeStateMachine/conditions/is_grounded", is_on_floor())
	
	#attack
	var is_attacking: bool = anim_tree.get("parameters/OneShot/active")
	if Input.is_action_just_pressed("Attack") and not is_attacking:
		if current_stamina >= attack_cost:
			current_stamina -= attack_cost
			stamina_delay_timer = 0.0
			anim_tree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			fist_hitbox.monitoring = true
			get_tree().create_timer(0.4).timeout.connect(func(): fist_hitbox.monitoring = false)
	move_and_slide()
	
func start_dodge(current_direction: Vector3) -> void:
	is_dodging = true
	if current_direction == Vector3.ZERO:
		dodge_direction = (camera_pivot.global_transform.basis * Vector3(0,0,1))
	else:
		dodge_direction = current_direction
		
	get_tree().create_timer(dodge_duration).timeout.connect(func(): is_dodging = false)


func _on_fist_hitbox_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		# Deal 25 damage to the enemy
		body.take_damage(25)

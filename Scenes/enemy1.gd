extends CharacterBody3D

@export_category("Enemy Stats")
@export var max_health: int = 100
@export var speed: float = 0.5
@export var attack_range: float = 1.0
@export var attack_cooldown: float = 2.0

var current_health: int
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# AI Variables
var player: Node3D = null
var is_attacking: bool = false
var time_since_last_attack: float = 0.0

@onready var anim_player: AnimationPlayer = $visuals/AnimationPlayer


func _ready() -> void:
	current_health = max_health
	
	# Ask Godot to find the node we just put in the "player" group!
	var players_in_world = get_tree().get_nodes_in_group("player")
	if players_in_world.size() > 0:
		player = players_in_world[0]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# Timer to prevent the enemy from spamming attacks
	time_since_last_attack += delta

	# --- THE AI BRAIN ---
	if player != null and not is_attacking:
		# Calculate the distance between the enemy and the player
		var distance_to_player = global_position.distance_to(player.global_position)
		
		if distance_to_player > attack_range:
			chase_player()
		else:
			attack_player()
			
	move_and_slide()

func chase_player() -> void:
	# 1. Face the player
	var target_pos = player.global_position
	target_pos.y = global_position.y # Keep the Y axis flat so the enemy doesn't tilt into the floor!
	
	# The 'true' at the end fixes the Mixamo "Moonwalking" bug!
	look_at(target_pos, Vector3.UP) 
	
	# 2. Move towards the player
	var direction = (player.global_position - global_position).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	# 3. Play the running animation (0.2 is the crossfade time so it blends smoothly!)
	# CHANGE "Walk" to the exact name of your Mixamo run animation!
	if anim_player.current_animation != "Walk2":
		anim_player.play("Walk2", 0.2) 

func attack_player() -> void:
	# Slam on the brakes
	velocity.x = 0
	velocity.z = 0
	
	# Check if our cooldown is finished
	if time_since_last_attack >= attack_cooldown:
		is_attacking = true
		time_since_last_attack = 0.0
		
		# CHANGE "Attack" to the exact name of your Mixamo attack animation!
		anim_player.play("Attack", 0.1)
		
		# Wait 1.0 seconds for the attack to finish before chasing again
		# (Change 1.0 to match the length of your attack animation)
		get_tree().create_timer(1.0).timeout.connect(func(): is_attacking = false)
	else:
		# If we are in range but waiting on cooldown, play the idle animation
		# CHANGE "Idle" to your exact animation name!
		if anim_player.current_animation != "idle":
			anim_player.play("idle", 0.2)

# --- THE HIT RECEIVER ---
func take_damage(damage_amount: int) -> void:
	current_health -= damage_amount
	print("Enemy Health: ", current_health)
	
	# Play a flinch/hit animation here if you imported one!
	
	if current_health <= 0:
		die()

func die() -> void:
	print("Enemy defeated")
	get_tree().create_timer(0.4).timeout.connect(func():queue_free())
	

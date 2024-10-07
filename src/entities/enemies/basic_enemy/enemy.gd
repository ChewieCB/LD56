extends CharacterBody2D
class_name Enemy

# SFX
@export var SFX_idle: AudioStream
@export var SFX_attack: Array[AudioStream]
@export var SFX_aggro: Array[AudioStream]
@export var SFX_death: Array[AudioStream]
@export var idle_player: AudioStreamPlayer2D

@export var speed = 100
@export var max_health: float = 100
# Attack
@export var attack_damage = 50
@export var time_between_attack = 1
@export var max_agent_per_attack = 3
# Wander
@export var min_wander_range = 100
@export var max_wander_range = 500
# Track
@export var detect_range = 200
@export var max_chase_range = 1000
# Dash
@export var range_to_dash = 300
@export var dash_speed = 700
@export var dash_delay = 0.5 # Aka reaction time, time the enemy need to prepare before dash
@export var dash_duration = 2
@export var dash_decel_rate = 1.0
# Flee
@export var min_agent_to_flee = 10
@export var min_flee_time = 2.0

@onready var state_chart: StateChart = $StateChart
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var detect_area: Area2D = $PlayerDetectRange
@onready var detect_collision_shape: CollisionShape2D = $PlayerDetectRange/CollisionShape2D
@onready var los_raycast: RayCast2D = $LOSRaycast
@onready var wasp_sprite: Node2D = $WaspSprite

var current_health: float = max_health:
	set(value):
		current_health = clamp(value, 0, max_health)
		if current_health == 0:
			state_chart.send_event("death")
var navigation_initialized = false
var spawn_pos: Vector2
var found_wander_pos = false
var dash_timer = 0
var dash_delay_timer = 0
var flee_timer = 0
var attack_cooldown_timer = 0
var dash_velocity: Vector2 = Vector2.ZERO
var n_swarm_agent_within_range = 0
var targeted_swarm_agent: SwarmAgent = null
var aggro_sfx_player: AudioStreamPlayer
var n_agent_killed_this_attack = 0

const ROTATION_SPEED = 4.0
const FLEE_SPEED_MODIFIER = 2

func _ready() -> void:
	# Wait for important nodes to register themselves to GameManagers
	await get_tree().physics_frame
	await get_tree().physics_frame

	current_health = max_health
	spawn_pos = global_position
	detect_collision_shape.shape.radius = detect_range
	detect_area.position = Vector2(detect_range * 0.5, 0)
	los_raycast.target_position = Vector2(range_to_dash, 0)

	if SFX_idle:
		idle_player.stream = SFX_idle

	GameManager.swarm_director.swarm_status_changed.connect(check_swarm_status)

	call_deferred("actor_setup")


func actor_setup():
	# Wait for navigation map finished initialize
	await get_tree().physics_frame
	await get_tree().physics_frame
	navigation_initialized = true


func _process(_delta: float) -> void:
	var dist_from_spawn = global_position.distance_to(spawn_pos)
	if dist_from_spawn >= max_chase_range:
		state_chart.send_event("stop_chase")

	if rotation_degrees > -90 and rotation_degrees < 90:
		wasp_sprite.scale.y = 0.4  # Facing right
	else:
		wasp_sprite.scale.y = -0.4   # Facing left

func _on_idle_state_entered() -> void:
	if idle_player.stream:
		idle_player.play()
	# It will wait for a second before start to wander
	await get_tree().create_timer(1.0).timeout
	state_chart.send_event("wander_started")


func _on_detect_range_body_entered(body: Node2D) -> void:
	if body is SwarmAgent and not body.is_in_sealed_vessel:
		n_swarm_agent_within_range += 1
		if GameManager.swarm_director.is_spread_out \
			and GameManager.swarm_director.swarm_agent_count >= min_agent_to_flee:
			state_chart.send_event("flee_from_player")
		else:
			state_chart.send_event("player_spotted")

func _on_player_detect_range_body_exited(body: Node2D) -> void:
	if body is SwarmAgent and not body.is_in_sealed_vessel:
		n_swarm_agent_within_range -= 1


func _on_wander_state_entered() -> void:
	found_wander_pos = false
	# If far from spawn point, go back there instead of wander
	var dist_from_spawn = global_position.distance_to(spawn_pos)
	if dist_from_spawn >= max_chase_range:
		found_wander_pos = true
		nav_agent.target_position = spawn_pos
	while not found_wander_pos:
		# Wait for 0.1s before repeatly look for wander spot to prevent lag
		await get_tree().create_timer(0.1).timeout
		get_new_wander_pos()


func _on_wander_state_physics_processing(delta: float) -> void:
	if not navigation_initialized:
		return
	var current_position = global_position
	var next_position = nav_agent.get_next_path_position()
	var move_dir = (next_position - current_position).normalized()
	velocity = move_dir * speed
	keep_looking_at_pos(delta, next_position)
	move_and_slide()


func get_new_wander_pos():
	# Get a random position within wander range
	var angle = randf() * TAU # Random angle between 0 and 2π (TAU)
	var distance = lerp(min_wander_range, max_wander_range, randf())
	var random_offset = Vector2(cos(angle), sin(angle)) * distance
	var wander_pos = spawn_pos + random_offset

	# Check if the position is legit
	var nav_map = nav_agent.get_navigation_map();
	found_wander_pos = NavigationServer2D.map_get_closest_point(nav_map, wander_pos).is_equal_approx(wander_pos)
	if found_wander_pos:
		nav_agent.target_position = wander_pos


func _on_track_state_entered() -> void:
	targeted_swarm_agent = GameManager.swarm_director.get_furthest_agent()

	if not aggro_sfx_player:
		aggro_sfx_player = GlobalSFX.play_sfx_shuffled(SFX_aggro)

	if targeted_swarm_agent == null:
		state_chart.send_event("stop_chase")
		return
	nav_agent.target_position = targeted_swarm_agent.global_position


func _on_track_state_physics_processing(delta: float) -> void:
	if targeted_swarm_agent == null:
		state_chart.send_event("stop_chase")
		return

	if targeted_swarm_agent.global_position.distance_to(global_position) <= range_to_dash:
		if not los_raycast.is_colliding():
			state_chart.send_event("dash_started")

	# It chase until the target is within range_to_dash
	if not navigation_initialized:
		return
	nav_agent.target_position = targeted_swarm_agent.global_position
	var current_position = global_position
	var next_position = nav_agent.get_next_path_position()
	var move_dir = (next_position - current_position).normalized()
	velocity = move_dir * speed
	keep_looking_at_pos(delta, next_position)
	move_and_slide()


func _on_track_state_exited() -> void:
	if aggro_sfx_player and is_instance_valid(aggro_sfx_player):
		var tween = get_tree().create_tween()
		tween.tween_property(
			aggro_sfx_player,
			"volume_db",
			-100.0,
			0.2
		).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(aggro_sfx_player.stop)
		tween.tween_callback(aggro_sfx_player.queue_free)


func _on_navigation_agent_2d_target_reached() -> void:
	state_chart.send_event("target_reached")


func _on_dash_state_entered() -> void:
	if targeted_swarm_agent == null:
		state_chart.send_event("back_to_track")
		return

	dash_delay_timer = dash_delay
	dash_timer = dash_duration


func _on_dash_state_physics_processing(delta: float) -> void:
	if targeted_swarm_agent == null:
		state_chart.send_event("back_to_track")
		return

	dash_delay_timer -= delta
	if dash_delay_timer > 0:
		keep_looking_at_pos(delta, targeted_swarm_agent.global_position)
		var move_dir = (targeted_swarm_agent.global_position - global_position).normalized()
		dash_velocity = move_dir * dash_speed
		return

	dash_timer -= delta
	if dash_timer <= 0.0:
		state_chart.send_event("back_to_track")

	# Apply deceleration to the dash velocity
	dash_velocity = dash_velocity.lerp(Vector2.ZERO, dash_decel_rate * delta)
	velocity = dash_velocity
	move_and_slide()


func keep_looking_at_pos(delta: float, target_pos: Vector2):
	var target_dir = target_pos - global_position
	var target_angle = target_dir.angle()
	rotation = lerp_angle(rotation, target_angle, ROTATION_SPEED * delta)

func check_swarm_status():
	if GameManager.swarm_director.is_spread_out \
		and n_swarm_agent_within_range > 0 \
		and GameManager.swarm_director.swarm_agent_count >= min_agent_to_flee:
		state_chart.send_event("flee_from_player")

func _on_flee_state_entered() -> void:
	flee_timer = 0

func _on_flee_state_physics_processing(delta: float) -> void:
	flee_timer += delta
	if flee_timer > min_flee_time:
		state_chart.send_event("stop_fleeing")
	var direction_away = (global_position - GameManager.swarm_director.target.global_position).normalized()
	velocity = direction_away * speed * FLEE_SPEED_MODIFIER
	keep_looking_at_pos(delta, global_position + direction_away)
	move_and_slide()


func damage(value: float) -> void:
	if value > 0:
		state_chart.send_event("take_damage")
		current_health -= value


func _on_attack_range_body_entered(body: Node2D) -> void:
	if body is SwarmAgent and not body.is_in_sealed_vessel:
		var agent: SwarmAgent = body as SwarmAgent
		if n_agent_killed_this_attack < max_agent_per_attack:
			n_agent_killed_this_attack += 1
			agent.damage(attack_damage)
			GlobalSFX.play_sfx_shuffled(SFX_attack)
		state_chart.send_event("attack_player")


func _on_cooldown_state_entered() -> void:
	attack_cooldown_timer = time_between_attack

func _on_cooldown_state_processing(delta: float) -> void:
	attack_cooldown_timer -= delta
	if attack_cooldown_timer <= 0:
		state_chart.send_event("attack_ready")


func _on_ready_state_entered() -> void:
	n_agent_killed_this_attack = 0


func _on_attacking_state_entered() -> void:
	# Play animation or something here. For now, it will just wait 0.5s
	await get_tree().create_timer(0.5).timeout
	state_chart.send_event("attack_finished")


func _on_dead_state_entered() -> void:
	GlobalSFX.play_sfx_shuffled(SFX_death)

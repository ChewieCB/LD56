extends CharacterBody2D
class_name Enemy

@export var speed = 100
@export var max_hp = 100
@export var min_wander_range = 100
@export var max_wander_range = 500
@export var detect_range = 256
@export var range_to_dash = 150
@export var dash_speed = 600
@export var dash_delay = 0.5 # Aka reaction time, time the enemy need to prepare before dash
@export var dash_duration = 2.5
@export var dash_decel_rate = 1.0
@export var max_chase_range = 1000

@onready var state_chart: StateChart = $StateChart
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var detect_collision_shape: CollisionShape2D = $PlayerDetectRange/CollisionShape2D
@onready var los_raycast: RayCast2D = $LOSRaycast

var current_hp = 100
var navigation_initialized = false
var spawn_pos: Vector2
var found_wander_pos = false
var dash_timer = 0
var dash_delay_timer = 0
var dash_velocity: Vector2 = Vector2.ZERO
var swarm_agent_within_range = false
var targeted_swarm_agent: SwarmAgent = null

const ROTATION_SPEED = 4.0
const FLEE_SPEED_MODIFIER = 1.5

func _ready() -> void:
	# Wait for important nodes to register themselves to GameManagers
	await get_tree().physics_frame
	await get_tree().physics_frame
	current_hp = max_hp
	spawn_pos = global_position
	detect_collision_shape.shape.radius = detect_range
	GameManager.swarm_director.swarm_status_changed.connect(check_swarm_status)
	call_deferred("actor_setup")


func actor_setup():
	# Wait for navigation map finished initialize
	await get_tree().physics_frame
	await get_tree().physics_frame
	navigation_initialized = true


func _physics_process(_delta: float) -> void:
	var dist_from_spawn = global_position.distance_to(spawn_pos)
	if dist_from_spawn >= max_chase_range:
		state_chart.send_event("stop_chase")


func _on_idle_state_entered() -> void:
	# It will wait for a second before start to wander
	await get_tree().create_timer(1.0).timeout
	state_chart.send_event("wander_started")


func _on_detect_range_body_entered(body: Node2D) -> void:
	if body is SwarmAgent:
		swarm_agent_within_range = true
		if GameManager.swarm_director.is_fire:
			state_chart.send_event("flee_from_player")
		else:
			state_chart.send_event("player_spotted")

func _on_player_detect_range_body_exited(body: Node2D) -> void:
	if body is SwarmAgent:
		swarm_agent_within_range = false
		state_chart.send_event("player_faraway")


func _on_wander_state_entered() -> void:
	found_wander_pos = false
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
	# Look at moving position
	var target_angle = velocity.angle()
	rotation = lerp_angle(rotation, target_angle, ROTATION_SPEED * delta)
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
	targeted_swarm_agent = GameManager.swarm_director.get_furtherst_agent()
	if targeted_swarm_agent == null:
		state_chart.send_event("stop_chase")
		return
	nav_agent.target_position = targeted_swarm_agent.global_position


func _on_track_state_physics_processing(delta: float) -> void:
	if targeted_swarm_agent == null:
		state_chart.send_event("stop_chase")
		return

	if targeted_swarm_agent.global_position.distance_to(global_position) <= range_to_dash:
		state_chart.send_event("dash_started")

	# It chase until the target is within range_to_dash
	if not navigation_initialized:
		return
	nav_agent.target_position = targeted_swarm_agent.global_position
	var current_position = global_position
	var next_position = nav_agent.get_next_path_position()
	var move_dir = (next_position - current_position).normalized()
	velocity = move_dir * speed
	# Look at moving position
	var target_angle = velocity.angle()
	rotation = lerp_angle(rotation, target_angle, ROTATION_SPEED * delta)
	move_and_slide()


func _on_navigation_agent_2d_target_reached() -> void:
	state_chart.send_event("target_reached")


func _on_dash_state_entered() -> void:
	if targeted_swarm_agent == null:
		state_chart.send_event("back_to_track")
		return
	
	var target_dir = targeted_swarm_agent.global_position - global_position
	target_dir = target_dir.rotated(-rotation) # Take into account current enemy rotation
	los_raycast.target_position = target_dir
	if los_raycast.is_colliding():
		state_chart.send_event("back_to_track")
		return

	dash_delay_timer = dash_delay
	dash_timer = dash_duration


func _on_dash_state_physics_processing(delta: float) -> void:
	if targeted_swarm_agent == null:
		state_chart.send_event("back_to_track")

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
	if GameManager.swarm_director.is_fire and swarm_agent_within_range:
		state_chart.send_event("flee_from_player")

func _on_flee_state_physics_processing(delta: float) -> void:
	var direction_away = (global_position - GameManager.swarm_director.centroid.global_position).normalized()
	velocity = direction_away * speed * FLEE_SPEED_MODIFIER
	keep_looking_at_pos(delta, global_position + velocity)
	move_and_slide()

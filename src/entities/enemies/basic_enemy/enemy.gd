extends CharacterBody2D
class_name Enemy

@export var speed = 100
@export var max_hp = 100
@export var min_wander_range = 100
@export var max_wander_range = 500
@export var detect_range = 256
@export var dash_speed = 600
@export var dash_duration = 2.5
@export var dash_decel_rate = 1.0

@onready var state_chart: StateChart = $StateChart
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var detect_collision_shape: CollisionShape2D = $PlayerDetectRange/CollisionShape2D

var current_hp = 100
var navigation_initialized = false
var spawn_pos: Vector2
var found_wander_pos = false
var dash_timer = 0
var dash_velocity: Vector2 = Vector2.ZERO
var player_within_range = false

const ROTATION_SPEED = 2.0
const TRACKING_ROTATION_SPEED = 3.0
const FLEE_SPEED_MODIFIER = 0.75

func _ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	current_hp = max_hp
	spawn_pos = global_position
	detect_collision_shape.shape.radius = detect_range
	call_deferred("actor_setup")
	GameManager.player.change_status.connect(check_player_status)


func actor_setup():
	await get_tree().physics_frame
	await get_tree().physics_frame
	navigation_initialized = true


func _physics_process(_delta: float) -> void:
	return


func _on_idle_state_entered() -> void:
	# It will wait for a second before start to wander
	await get_tree().create_timer(1.0).timeout
	state_chart.send_event("wander_started")


func _on_detect_range_body_entered(body: Node2D) -> void:
	if body is Player:
		player_within_range = true
		var player: Player = body as Player
		if player.is_fire:
			state_chart.send_event("flee_from_player")
		else:
			state_chart.send_event("player_spotted")

func _on_player_detect_range_body_exited(body: Node2D) -> void:
	if body is Player:
		player_within_range = false
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
	rotation = lerp_angle(rotation, target_angle, TRACKING_ROTATION_SPEED * delta)
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
	# It will wait for a second before dash
	await get_tree().create_timer(1.0).timeout
	state_chart.send_event("dash_started")


func _on_track_state_physics_processing(delta: float) -> void:
	keep_looking_at_player(delta)


func _on_navigation_agent_2d_target_reached() -> void:
	state_chart.send_event("target_reached")


func _on_dash_state_entered() -> void:
	dash_timer = dash_duration
	var move_dir = (GameManager.player.global_position - global_position).normalized()
	dash_velocity = move_dir * dash_speed # Set initial dash velocity


func _on_dash_state_physics_processing(delta: float) -> void:
	keep_looking_at_player(delta)
	dash_timer -= delta
	if dash_timer <= 0.0:
		state_chart.send_event("back_to_track")

	# Apply deceleration to the dash velocity
	dash_velocity = dash_velocity.lerp(Vector2.ZERO, dash_decel_rate * delta)
	velocity = dash_velocity
	move_and_slide()


func keep_looking_at_player(delta: float):
	var player_dir = GameManager.player.global_position - global_position
	var target_angle = player_dir.angle()
	rotation = lerp_angle(rotation, target_angle, TRACKING_ROTATION_SPEED * delta)

func check_player_status():
	if GameManager.player.is_fire and player_within_range:
		state_chart.send_event("flee_from_player")

func _on_flee_state_physics_processing(delta: float) -> void:
	keep_looking_at_player(delta)
	var direction_away = (global_position - GameManager.player.global_position).normalized()
	velocity = direction_away * speed * FLEE_SPEED_MODIFIER
	move_and_slide()

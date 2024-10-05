extends CharacterBody2D
class_name Enemy

@export var speed = 100
@export var max_hp = 100
@export var min_wander_range = 100
@export var max_wander_range = 500

@onready var state_chart: StateChart = $StateChart
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var current_hp = 100
var navigation_initialized = false
var spawn_pos: Vector2
var found_wander_pos = false

const ROTATION_SPEED = 2.0

func _ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	current_hp = max_hp
	spawn_pos = global_position
	call_deferred("actor_setup")

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
		state_chart.send_event("player_spotted")

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
	# Keep looking at player
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

func _on_navigation_agent_2d_target_reached() -> void:
	state_chart.send_event("target_reached")


func _on_track_state_entered() -> void:
	# It will wait for a second before dash
	await get_tree().create_timer(1.0).timeout

func _on_track_state_physics_processing(delta: float) -> void:
	# Keep looking at player
	var player_dir = GameManager.player.global_position - global_position
	var target_angle = player_dir.angle()
	rotation = lerp_angle(rotation, target_angle, ROTATION_SPEED * 1.5 * delta)

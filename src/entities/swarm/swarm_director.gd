extends Node2D
class_name SwarmDirector

signal swarm_status_changed
signal close_formation
signal normal_formation
signal far_formation

# SFX
@export var SFX_agent_spawn: Array[AudioStream]
@export var SFX_agent_hurt: Array[AudioStream]
@export var SFX_agent_death: Array[AudioStream]
@export var SFX_swarm_expand: Array[AudioStream]
@export var SFX_swarm_contract: Array[AudioStream]

@export var SFX_swarm_move: AudioStream
var active_movement_sfx_player: AudioStreamPlayer
var movement_sfx_tween: Tween
var max_simultaneous_sfx: int = 100
var active_hurt_sfx_players: Array[AudioStreamPlayer]
var active_death_sfx_players: Array[AudioStreamPlayer]

@export var state_chart: StateChart
@export var swarm_agent_scene: PackedScene
@export var swarm_agent_count: int = 0:
	set(value):
		swarm_agent_count = value
		var swarm_volume_linear: float = clamp(float(swarm_agent_count) / 50, 0.0, 1.0)
		if active_movement_sfx_player:
			movement_sfx_tween = get_tree().create_tween()
			movement_sfx_tween.tween_property(
				active_movement_sfx_player,
				"volume_db",
				linear_to_db(clamp(float(swarm_volume_linear) / 20, 0, 1)),
				0.01
			)
@export var target_max_speed: float = 250.0
@export var target_movement_speed: float = 230.0
@export var target_acceleration: float = 0.82
@export var target_friction: float = 0.06

@onready var target: CharacterBody2D = $TargetMarker
@onready var target_sprite: Sprite2D = $TargetMarker/Sprite2D
@onready var centroid: Marker2D = $SwarmCentroidMarker
@onready var debug_status_sprite: Sprite2D = $SwarmCentroidMarker/Sprite2D
@onready var audio_2d_listener: AudioListener2D = $AudioListener2D

var swarm_agents: Array:
	set(value):
		swarm_agents = value
		if swarm_agents.size() != swarm_agent_count:
			swarm_agent_count = swarm_agents.size()
			GameManager.game_ui.update_agent_count_ui()
var removed_agent_debug: Vector2
var is_fire = false # Is on fire element, scare away predators
var navigation_initialized = false

var current_swarm_attributes: Dictionary
const SWARM_ATTRIBUTES_CLOSE: Dictionary = {
	"mouse_follow_force": 0.2,
	"cohesive_force": 0.5,
	"separation_force": 0.5,
	"max_speed": 250,
	"avoid_distance": 5.,
}
const SWARM_ATTRIBUTES_NORMAL: Dictionary = {
	"mouse_follow_force": 0.2,
	"cohesive_force": 0.5,
	"separation_force": 0.5,
	"max_speed": 200,
	"avoid_distance": 15.,
}
const SWARM_ATTRIBUTES_FAR: Dictionary = {
	"mouse_follow_force": 0.3,
	"cohesion_force": 0.25,
	"separation_force": 0.8,
	"max_speed": 180,
	"avoid_distance": 30.,
}

func _ready() -> void:
	randomize()
	debug_status_sprite.self_modulate = Color.GREEN
	GameManager.swarm_director = self
	
	if SFX_swarm_move:
		active_movement_sfx_player = SoundManager.play_sound(SFX_swarm_move)
		active_movement_sfx_player.volume_db = 0
	
	for _i in range(swarm_agent_count):
		await get_tree().create_timer(swarm_agent_count / 100).timeout
		add_agent()
	
	state_chart.send_event("enable_idle")

	await get_tree().physics_frame
	for obstacle in get_tree().get_nodes_in_group("obstacles"):
		obstacle.damage_swarm_agent.connect(damage_agent)
	call_deferred("actor_setup")


func actor_setup():
	# Wait for navigation map finished initialize
	await get_tree().physics_frame
	await get_tree().physics_frame
	navigation_initialized = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("DEBUG_player_toggle_fire_status"):
		is_fire = !is_fire
		swarm_status_changed.emit()
		if is_fire:
			debug_status_sprite.self_modulate = Color.ORANGE
		else:
			debug_status_sprite.self_modulate = Color.GREEN


func _physics_process(delta: float) -> void:
	target.move_and_slide()
	
	if Input.is_action_pressed("huddle"):
		state_chart.send_event("clump_together")
	elif Input.is_action_just_released("huddle"):
		state_chart.send_event("reset_distribution")
	elif Input.is_action_just_pressed("spread"):
		state_chart.send_event("spread_out")
	elif Input.is_action_just_released("spread"):
		state_chart.send_event("reset_distribution")
	
	
	if Input.is_action_just_pressed("DEBUG_add_agent"):
		add_agent()
	elif Input.is_action_just_pressed("DEBUG_remove_agent"):
		if swarm_agents:
			damage_agent(swarm_agents[randi_range(0, swarm_agents.size() - 1)], 2000)
	
	get_nav_path_for_swarm_agents(delta)

	# Get centroid position of swarm
	var avg_agent_pos := Vector2.ZERO
	if swarm_agents:
		for agent in swarm_agents:
			avg_agent_pos += agent.global_position
		avg_agent_pos /= swarm_agents.size()
		centroid.global_position = avg_agent_pos
	else:
		centroid.global_position = target.global_position
	
	audio_2d_listener.global_position = centroid.global_position


func _process(_delta):
	queue_redraw()


func get_nav_path_for_swarm_agents(_delta: float) -> void:
	if not navigation_initialized:
		return
	var nav_map: RID = get_world_2d().get_navigation_map()
	swarm_agents = GameManager.clean_array(swarm_agents)
	for agent in swarm_agents:
		var from_pos: Vector2 = agent.global_position
		var to_pos: Vector2 = agent.target.global_position
		agent.target_path = NavigationServer2D.map_get_path(nav_map, from_pos, to_pos, true)


func add_agent(new_position: Vector2 = centroid.global_position) -> SwarmAgent:
	var new_agent = swarm_agent_scene.instantiate()
	new_agent.position = to_local(new_position)
	new_agent.target = target
	
	new_agent.died.connect(func(_agent):
		GlobalSFX.play_batched_sfx(
			SFX_agent_death, active_death_sfx_players,
			max_simultaneous_sfx, -12.0, true
		)
	)
	
	call_deferred("add_child", new_agent)

	if new_agent not in swarm_agents:
		swarm_agents.append(new_agent)
		swarm_agent_count = swarm_agents.size()

	for key in current_swarm_attributes.keys():
		new_agent.set(key, current_swarm_attributes[key])
	
	GlobalSFX.play_sfx_shuffled(SFX_agent_spawn, "", true)
	GameManager.game_ui.update_agent_count_ui()
	
	return new_agent


func damage_agent(agent: SwarmAgent, damage: float) -> void:
	agent.damage(damage)
	GlobalSFX.play_batched_sfx(
		SFX_agent_hurt, active_hurt_sfx_players,
		max_simultaneous_sfx, -8.0
	)


func remove_agent(agent: SwarmAgent) -> void:
	swarm_agents.erase(agent)
	swarm_agent_count = swarm_agents.size()
	GameManager.game_ui.update_agent_count_ui()


# Run on agent dead
func check_game_over():
	# Minus 1 because when we run this check, the died swarm agent still
	# not queue_freed yet
	var agent_left = swarm_agents.size() - 1
	if agent_left <= 0:
		GameManager.game_over()


func set_swarm_attributes(attributes: Dictionary) -> void:
	for agent in swarm_agents:
		if is_instance_valid(agent):
			for key in attributes.keys():
				agent.set(key, attributes[key])


func get_furthest_agent():
	var chosen_agent = null
	var max_dist = 0
	swarm_agents = GameManager.clean_array(swarm_agents)
	for agent in swarm_agents:
		var dist = centroid.global_position.distance_squared_to(agent.global_position)
		if dist > max_dist:
			max_dist = dist
			chosen_agent = agent
	return chosen_agent


func _on_distribution_normal_state_entered() -> void:
	target_movement_speed = 230.0
	set_swarm_attributes(SWARM_ATTRIBUTES_NORMAL)
	# Hacky so we can set on agent add
	normal_formation.emit()


func _on_distribution_close_state_entered() -> void:
	target_movement_speed = 280.0
	set_swarm_attributes(SWARM_ATTRIBUTES_CLOSE)
	# Hacky so we can set on agent add
	current_swarm_attributes = SWARM_ATTRIBUTES_CLOSE
	close_formation.emit()
	GlobalSFX.play_sfx_shuffled(SFX_swarm_contract)

func _on_distribution_close_state_exited() -> void:
	GlobalSFX.play_sfx_shuffled(SFX_swarm_expand)


func _on_distribution_far_state_entered() -> void:
	target_movement_speed = 210.0
	set_swarm_attributes(SWARM_ATTRIBUTES_FAR)
	# Hacky so we can set on agent add
	current_swarm_attributes = SWARM_ATTRIBUTES_FAR
	far_formation.emit()
	GlobalSFX.play_sfx_shuffled(SFX_swarm_expand)

func _on_distribution_far_state_exited() -> void:
	GlobalSFX.play_sfx_shuffled(SFX_swarm_contract)


func _on_moving_state_entered() -> void:
	pass
	# TODO - add movement speed SFX or volume increase hook
	#if SFX_swarm_move:
		#active_movement_sfx_player = SoundManager.play_sound(SFX_swarm_move)
		#active_movement_sfx_player.volume_db = linear_to_db(0)
		#movement_sfx_tween = get_tree().create_tween()
		#movement_sfx_tween.tween_property(
			#active_movement_sfx_player,
			#"volume_db",
			#-20.0, # TODO - parameterize
			#0.05 # TODO - base on speed
		#).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)


func _on_moving_state_physics_processing(_delta: float) -> void:
	var direction = Vector2.ZERO
	direction = Input.get_vector("left", "right", "up", "down").normalized()

	if direction != Vector2.ZERO:
		target.velocity = lerp(target.velocity, direction * target_movement_speed, target_acceleration)
	else:
		state_chart.send_event("stop_moving")


func _on_moving_state_exited() -> void:
	pass
	# TODO - add movement speed SFX or volume increase hook
	#if SFX_swarm_move:
		#if active_movement_sfx_player:
			#movement_sfx_tween = get_tree().create_tween()
			#movement_sfx_tween.tween_property(
				#active_movement_sfx_player,
				#"volume_db",
				#-40.0, # TODO - parameterize
				#2.0 # TODO - base on speed
			#).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)


func _on_idle_state_entered() -> void:
	target_sprite.modulate = Color(1, 1, 1)


func _on_idle_state_physics_processing(_delta: float) -> void:
	var direction = Vector2.ZERO
	direction = Input.get_vector("left", "right", "up", "down").normalized()
	
	if direction != Vector2.ZERO:
		state_chart.send_event("start_moving")
		return
	
	target.velocity = lerp(target.velocity, Vector2.ZERO, target_friction)


func _on_disabled_state_entered() -> void:
	target_sprite.modulate = Color.RED

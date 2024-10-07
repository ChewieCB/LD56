extends Node2D
class_name NPCSwarm

signal swarm_status_changed

@export var swarm_id: int = 2:
	set(value):
		var changed = swarm_id != value
		swarm_id = value
		if changed:
			for agent in swarm_agents:
				if agent.swarm_id != swarm_id:
					agent.swarm_id = swarm_id
@export var swarm_join_range: float = 200
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

@export var gather_area_collider: CollisionShape2D
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
@onready var debug_status_sprite: Sprite2D = $SwarmCentroidMarker/DEBUGStatus
@onready var swarm_audio_player: AudioStreamPlayer2D = $SwarmAudio2D
@onready var swarm_director: SwarmDirector = GameManager.swarm_director

var swarm_agents: Array:
	set(value):
		swarm_agents = value
		if swarm_agents.size() != swarm_agent_count:
			swarm_agent_count = swarm_agents.size()
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
	target.visible = false
	debug_status_sprite.self_modulate = Color.GREEN
	gather_area_collider.shape.radius = swarm_join_range
	
	swarm_audio_player.play()
	
	for _i in range(swarm_agent_count):
		var _agent = add_agent()
		_agent.sprite.modulate = Color.PURPLE
	
	await get_tree().physics_frame
	call_deferred("actor_setup")


func actor_setup():
	# Wait for navigation map finished initialize
	await get_tree().physics_frame
	await get_tree().physics_frame
	navigation_initialized = true


func _physics_process(delta: float) -> void:
	if swarm_agent_count == 0:
		return
	
	target.move_and_slide()
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
	
	swarm_audio_player.global_position = centroid.global_position
	
	#if Input.is_action_just_pressed("DEBUG_release_npc_swarm"):
		#if self.target.global_position.distance_to(
			#swarm_director.target.global_position
		#) < swarm_join_range:
			#release_all_agents_to_director()


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
	new_agent.swarm_id = swarm_id
	new_agent.target = target
	
	new_agent.collision_layer = int(pow(2, 9 - 1))
	
	new_agent.died.connect(func(_agent):
		GlobalSFX.play_batched_sfx(
			SFX_agent_death, active_death_sfx_players,
			max_simultaneous_sfx, -12.0, true
		)
	)
	
	call_deferred("add_child", new_agent)
	call_deferred("set_agent_color", new_agent, Color.PURPLE)

	if new_agent not in swarm_agents:
		swarm_agents.append(new_agent)
		swarm_agent_count = swarm_agents.size()

	for key in current_swarm_attributes.keys():
		new_agent.set(key, current_swarm_attributes[key])
	
	return new_agent


func set_agent_color(agent: SwarmAgent, color: Color) -> void:
	agent.sprite.modulate = color


func set_agent_close(agent: SwarmAgent):
	for key in SWARM_ATTRIBUTES_CLOSE.keys():
		agent.set(key, SWARM_ATTRIBUTES_CLOSE[key])


func set_agent_normal(agent: SwarmAgent):
	for key in SWARM_ATTRIBUTES_NORMAL.keys():
		agent.set(key, SWARM_ATTRIBUTES_NORMAL[key])


func remove_agent(agent: SwarmAgent) -> void:
	if agent in swarm_agents:
		swarm_agents.erase(agent)
		swarm_agent_count = swarm_agents.size()


func set_swarm_attributes(attributes: Dictionary) -> void:
	for agent in swarm_agents:
		if is_instance_valid(agent):
			for key in attributes.keys():
				agent.set(key, attributes[key])


func release_all_agents_to_director():
	for agent in swarm_agents:
		agent.swarm_id = 0
		swarm_director.swarm_agents.append(agent)
		agent.target = swarm_director.target
		agent.sprite.modulate = Color(1, 1, 1)
		agent.collision_layer = int(pow(2, 2 - 1))
		set_agent_normal(agent)
	
	swarm_agents = []
	swarm_agent_count = 0

func _on_distribution_normal_state_entered() -> void:
	target_movement_speed = 230.0
	set_swarm_attributes(SWARM_ATTRIBUTES_NORMAL)
	# Hacky so we can set on agent add
	current_swarm_attributes = SWARM_ATTRIBUTES_NORMAL


func _on_distribution_close_state_entered() -> void:
	target_movement_speed = 280.0
	set_swarm_attributes(SWARM_ATTRIBUTES_CLOSE)
	# Hacky so we can set on agent add
	current_swarm_attributes = SWARM_ATTRIBUTES_CLOSE


func _on_distribution_far_state_entered() -> void:
	target_movement_speed = 210.0
	set_swarm_attributes(SWARM_ATTRIBUTES_FAR)
	# Hacky so we can set on agent add
	current_swarm_attributes = SWARM_ATTRIBUTES_FAR

func _on_distribution_far_state_exited() -> void:
	GlobalSFX.play_sfx_shuffled(SFX_swarm_contract)


func _on_disabled_state_entered() -> void:
	target_sprite.modulate = Color.RED


func _on_gather_area_body_entered(body: Node2D) -> void:
	if body.get_parent() is SwarmDirector:
		release_all_agents_to_director()

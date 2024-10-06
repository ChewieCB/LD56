extends Node2D
class_name SwarmDirector

@export var state_chart: StateChart
@export var swarm_agent_scene: PackedScene
@export var normal_separation: float = 0.5
@export var close_separation: float = 0.2
@export var far_separation: float = 4.0
@export var swarm_agent_count: int = 50
@export var target_movement_speed: float = 250.0
@export var target_acceleration: float = 0.82
@export var target_friction: float = 0.06

@onready var target: CharacterBody2D = $TargetMarker
@onready var centroid: Marker2D = $SwarmCentroidMarker
@onready var debug_status_sprite: Sprite2D = $SwarmCentroidMarker/DEBUGStatus

var swarm_agents: Array:
	set(value):
		swarm_agents = value
		swarm_agent_count = swarm_agents.size()
var removed_agent_debug: Vector2
var is_fire = false # Is on fire element, scare away predators

signal swarm_status_changed

func _ready() -> void:
	debug_status_sprite.self_modulate = Color.GREEN
	GameManager.swarm_director = self
	for _i in range(swarm_agent_count):
		randomize()
		var agent = swarm_agent_scene.instantiate()
		agent.position = Vector2(randf_range(-100, 100), randf_range(-100, 100))
		agent.target = target
		agent.died.connect(remove_agent)
		add_child(agent)
		if agent not in swarm_agents:
			swarm_agents.append(agent)
	
	await get_tree().physics_frame
	for obstacle in get_tree().get_nodes_in_group("obstacles"):
		obstacle.damage_swarm_agent.connect(damage_agent)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("DEBUG_player_toggle_fire_status"):
		is_fire = !is_fire
		swarm_status_changed.emit()
		if is_fire:
			debug_status_sprite.self_modulate = Color.ORANGE
		else:
			debug_status_sprite.self_modulate = Color.GREEN


func _physics_process(delta: float) -> void:
	var direction = Vector2.ZERO
	direction = Input.get_vector("left", "right", "up", "down").normalized()
	
	if direction != Vector2.ZERO:
		target.velocity = lerp(target.velocity, direction * target_movement_speed, target_acceleration)
	else:
		target.velocity = lerp(target.velocity, Vector2.ZERO, target_friction)
	
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


func _process(_delta):
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
	
	queue_redraw()


func get_nav_path_for_swarm_agents(_delta: float) -> void:
	var nav_map: RID = get_world_2d().get_navigation_map()
	swarm_agents = GameManager.clean_array(swarm_agents)
	for agent in swarm_agents:
		var from_pos: Vector2 = agent.global_position
		var to_pos: Vector2 = target.global_position
		agent.target_path = NavigationServer2D.map_get_path(nav_map, from_pos, to_pos, true)


func add_agent(new_position: Vector2 = centroid.position) -> SwarmAgent:
	var new_agent = swarm_agent_scene.instantiate()
	new_agent.position = new_position
	new_agent.target = target
	add_child(new_agent)
	
	if new_agent not in swarm_agents:
		swarm_agents.append(new_agent)
		swarm_agent_count = swarm_agents.size()
	
	return new_agent


func damage_agent(agent: SwarmAgent, damage: float) -> void:
	agent.damage(damage)


func remove_agent(agent: SwarmAgent) -> void:
	swarm_agents.erase(agent)
	swarm_agent_count = swarm_agents.size()


func set_swarm_attributes(attributes: Dictionary) -> void:
	for agent in swarm_agents:
		if is_instance_valid(agent):
			for key in attributes.keys():
				agent.set(key, attributes[key])


func get_furtherst_agent():
	var chosen_agent = null
	var max_dist = 0
	for agent in swarm_agents:
		var dist = centroid.global_position.distance_squared_to(agent.global_position)
		if dist > max_dist:
			max_dist = dist
			chosen_agent = agent
	return chosen_agent


func _on_distribution_normal_state_entered() -> void:
	set_swarm_attributes(
		{
			"mouse_follow_force": 0.05,
			"cohesive_force": 0.05,
			"separation_force": normal_separation,
			"max_speed": 270,
			"avoid_distance": 10.,
			"collision_radius": 5.,
		}
	)


func _on_distribution_close_state_entered() -> void:
	set_swarm_attributes(
		{
			"mouse_follow_force": 0.08,
			"cohesive_force": 0.1,
			"separation_force": close_separation,
			"max_speed": 380,
			"avoid_distance": 5.,
			"collision_radius": 3.,
		}
	)


func _on_distribution_far_state_entered() -> void:
	set_swarm_attributes(
		{
			"mouse_follow_force": 0.03,
			"cohesion_force": 0.04,
			"separation_force": far_separation,
			"max_speed": 200,
			"avoid_distance": 15.,
			"collision_radius": 9.,
		}
	)

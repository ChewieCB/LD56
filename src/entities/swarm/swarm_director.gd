extends Node2D
class_name SwarmDirector

@export var state_chart: StateChart

@export var swarm_agent_scene: PackedScene

@export var normal_separation: float = 0.5
@export var close_separation: float = 0.2
@export var far_separation: float = 4.0

var swarm_agents: Array[Node]:
	set(value):
		swarm_agents = value
		swarm_agent_count = swarm_agents.size()
@export var swarm_agent_count: int = 50

@onready var target: Marker2D = $TargetMarker


func _ready() -> void:
	for _i in range(swarm_agent_count):
		randomize()
		var agent = swarm_agent_scene.instantiate()
		agent.position = Vector2(randf_range(-100, 100), randf_range(-100, 100))
		agent.target = target
		add_child(agent)
		if agent not in swarm_agents:
			swarm_agents.append(agent)


func _physics_process(delta: float) -> void:
	var direction = Vector2.ZERO
	direction = Input.get_vector("left", "right", "up", "down")

	target.global_position = target.global_position.lerp(target.global_position + direction * 500, delta * 0.4)
	get_nav_path_for_swarm_agents(delta)


func _process(delta):
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
		remove_agent(swarm_agents[randi_range(0, swarm_agents.size() - 1)])


func get_nav_path_for_swarm_agents(delta: float) -> void:
	var nav_map: RID = get_world_2d().get_navigation_map()
	for agent in swarm_agents:
		var from_pos: Vector2 = agent.global_position
		var to_pos: Vector2 = target.global_position
		agent.target_path = NavigationServer2D.map_get_path(nav_map, from_pos, to_pos, true)


func add_agent(new_position: Vector2 = Vector2.ZERO) -> SwarmAgent:
	var new_agent = swarm_agent_scene.instantiate()
	new_agent.position = new_position
	new_agent.target = target
	add_child(new_agent)
	if new_agent not in swarm_agents:
		swarm_agents.append(new_agent)
		swarm_agent_count = swarm_agents.size()
	
	return new_agent


func remove_agent(agent: SwarmAgent) -> void:
	swarm_agents.erase(agent)
	swarm_agent_count = swarm_agents.size()
	agent.queue_free()


func set_swarm_attributes(attributes: Dictionary) -> void:
	for agent in swarm_agents:
		for key in attributes.keys():
			agent.set(key, attributes[key])


func _on_distribution_normal_state_entered() -> void:
	set_swarm_attributes(
		{
			"separation_force": normal_separation,
			"max_speed": 270,
			"avoid_distance": 10.,
			"collision_radius": 5.,
		}
	)


func _on_distribution_close_state_entered() -> void:
	set_swarm_attributes(
		{
			"separation_force": close_separation,
			"max_speed": 380,
			"avoid_distance": 5.,
			"collision_radius": 3.,
		}
	)


func _on_distribution_far_state_entered() -> void:
	set_swarm_attributes(
		{
			"separation_force": far_separation,
			"max_speed": 200,
			"avoid_distance": 15.,
			"collision_radius": 9.,
		}
	)

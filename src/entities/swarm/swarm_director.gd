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

	target.global_position = target.global_position.lerp(target.global_position + direction * 800, delta * 0.4)


func _process(delta):
	if Input.is_action_pressed("huddle"):
		state_chart.send_event("clump_together")
	elif Input.is_action_just_released("huddle"):
		state_chart.send_event("reset_distribution")
	elif Input.is_action_just_pressed("spread"):
		state_chart.send_event("spread_out")
	elif Input.is_action_just_released("spread"):
		state_chart.send_event("reset_distribution")


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

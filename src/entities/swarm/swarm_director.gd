extends Node2D
class_name SwarmDirector

@export var swarm_agent_scene: PackedScene

var swarm_agents: Array[Node]:
	set(value):
		swarm_agents = value
		swarm_agent_count = swarm_agents.size()
@export var swarm_agent_count: int = 50


func _ready() -> void:
	for _i in range(swarm_agent_count):
		randomize()
		var agent = swarm_agent_scene.instantiate()
		agent.position = Vector2(randf_range(-100, 100), randf_range(-100, 100))
		add_child(agent)
		if agent not in swarm_agents:
			swarm_agents.append(agent)

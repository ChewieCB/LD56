extends Node2D
class_name SwarmDirector

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var swarm_cluster: SwarmCluster = $SwarmCluster

var swarm_clusters: Array[Node]
var swarm_agents_by_cluster: Dictionary
var swarm_agents: Array[SwarmAgent]:
	set(value):
		swarm_agents = value
		swarm_agent_count = swarm_agents.size()
var swarm_agent_count: int


func _ready() -> void:
	swarm_clusters = get_tree().get_nodes_in_group("swarm_cluster")
		


func _physics_process(delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	for cluster in swarm_clusters:
		cluster.set_target(mouse_pos)
	



	

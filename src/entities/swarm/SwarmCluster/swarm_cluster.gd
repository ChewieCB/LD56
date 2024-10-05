extends CharacterBody2D
class_name SwarmCluster

@onready var collider = $CollisionShape2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

@onready var agent_parent: Node2D = $Agents
@onready var agents: Array[Node] = []:
	set(value):
		agents = value
		agent_count = agents.size()
var agent_count: int

@export var cluster_size: float = 16.0:
	set(value):
		cluster_size = value
		collider.shape.radius = cluster_size

@export var max_agents: int = 10
@export var min_agent_dist: float = 0.1
@export var max_agent_dist: float = 4.0

var speed = 2000
var accel = 8


func _ready() -> void:
	add_to_group("swarm_cluster")
	agents = agent_parent.get_children()


func set_target(target: Vector2) -> void:
	nav_agent.target_position = target


func _physics_process(delta: float) -> void:
	var next_path_pos = nav_agent.get_next_path_position()
	
	var current_agent_position = global_position
	var next_path_position = nav_agent.get_next_path_position()
	var new_velocity = current_agent_position.direction_to(next_path_position) * speed
	
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(new_velocity)
	else:
		_on_navigation_agent_2d_velocity_computed(new_velocity)
	
	move_and_slide()


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity

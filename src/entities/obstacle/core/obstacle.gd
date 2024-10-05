extends Node2D
class_name Obstacle

signal damage_swarm_agent(agent: SwarmAgent, damage: float)

@export var damage: float = 20.0


func _ready() -> void:
	add_to_group("obstacles")


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is SwarmAgent:
		emit_signal("damage_swarm_agent", body, damage)

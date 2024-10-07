extends Area2D
class_name WorldCloudTrigger


@export var thought_word_prefab: PackedScene
@export var world_list: Array[String] = []

@onready var duration_timer: Timer = $DurationTimer

var triggered = false

func _ready() -> void:
	triggered = false


func spawn_thought_word():
	var spawn_parent = GameManager.swarm_director.centroid
	for i in range(len(world_list)):
		var inst: ThoughtWord = thought_word_prefab.instantiate()
		var roll_range = 80 + GameManager.swarm_director.swarm_agent_count
		var random_x = randf_range(-roll_range, roll_range)
		var random_y = randf_range(-roll_range, roll_range)
		spawn_parent.add_child(inst)
		inst.assign_text(world_list[i], spawn_parent.global_position + Vector2(random_x, random_y))
		await get_tree().create_timer(1).timeout

func _on_body_entered(_body: Node2D) -> void:
	if not triggered:
		triggered = true
		spawn_thought_word()

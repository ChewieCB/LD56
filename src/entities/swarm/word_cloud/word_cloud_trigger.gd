extends Area2D
class_name WorldCloudTrigger


@export var thought_word_prefab: PackedScene
@export var world_list: Array[String] = []
@export var auto_trigger: bool = false

@onready var duration_timer: Timer = $DurationTimer

var triggered = false

func _ready() -> void:
	triggered = false
	if auto_trigger:
		trigger()


func trigger() -> void:
	triggered = true
	spawn_thought_word()


func spawn_thought_word():
	var spawn_parent = GameManager.swarm_director.centroid
	var last_word_spawn: Vector2
	for i in range(len(world_list)):
		var inst: ThoughtWord = thought_word_prefab.instantiate()
		var roll_range = 80 + GameManager.swarm_director.swarm_agent_count
		var spawn_pos = spawn_parent.global_position + Vector2(
			randf_range(-roll_range, roll_range),
			randf_range(-roll_range, roll_range) 
		)
		if last_word_spawn:
			if spawn_pos.distance_to_last_word_spawn < 40:
				spawn_pos = last_word_spawn.direction_to(spawn_pos) * 80
		
		spawn_parent.get_parent().add_child(inst)
		inst.assign_text(world_list[i], spawn_pos)
		await get_tree().create_timer(1).timeout


func _on_body_entered(_body: Node2D) -> void:
	if not triggered:
		if _body.get_parent() is SwarmDirector:
			trigger()

extends Area2D
class_name Checkpoint

@onready var flag_sprite: Sprite2D = $Sprite/Flag
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var activated = false
func _ready() -> void:
	flag_sprite.self_modulate = Color.RED


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("SwarmLeader") and not activated:
		activate_checkpoint()

func activate_checkpoint():
	activated = true
	var tween = get_tree().create_tween()
	tween.tween_property(flag_sprite, "self_modulate", Color.GREEN, 1.0)
	GameManager.checkpoint_activated = true
	GameManager.checkpoint_n_agents = GameManager.swarm_director.swarm_agent_count
	GameManager.checkpoint_position = GameManager.swarm_director.target.global_position
	audio_player.play()

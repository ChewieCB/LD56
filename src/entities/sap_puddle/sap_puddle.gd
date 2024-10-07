extends Node2D
class_name SapPuddle

@export var agents_count: int = 5

@export var SFX_sap_collected: Array[AudioStream]

@onready var puddle_mesh := $PuddleMesh
var is_consumed: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not is_consumed:
		if body is SwarmAgent or body is SwarmDirector:
			is_consumed = true
			
			GlobalSFX.play_sfx_shuffled(SFX_sap_collected)
			
			for agent in agents_count:
				GameManager.swarm_director.add_agent(self.position)
			
			var tween = get_tree().create_tween()
			tween.tween_property(
				puddle_mesh,
				"modulate:a", # scale:y don't work as we expected
				0,
				1
			)
			tween.tween_callback(self.queue_free)

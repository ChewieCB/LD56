extends Node2D
class_name SapPuddle

@export var agents_count: int = 5

@export var SFX_sap_collected: Array[AudioStream]

@onready var puddle_mesh := $PuddleMesh
@onready var collider: CollisionPolygon2D = $StaticBody2D/CollisionPolygon2D
@onready var agent_markers: Node2D = $AgentMarkers
var is_consumed: bool = false:
	set(value):
		is_consumed = value
		if is_consumed:
			regenerate()
			collider.disabled = false



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func regenerate() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(
		puddle_mesh,
		"scale:y",
		1,
		4.0
	).set_trans(Tween.TRANS_SINE)
	tween.set_parallel()
	tween.tween_property(
		puddle_mesh,
		"scale:x",
		1,
		4.0
	).set_trans(Tween.TRANS_LINEAR)
	tween.chain()
	for marker in agent_markers.get_children():
		var marker_sprite: Sprite2D = marker.get_node("SwarmSprite")
		tween.tween_property(
			marker_sprite,
			"modulate",
			Color(0.31, 0.31, 0.31, 1),
			0.6
		).set_trans(Tween.TRANS_LINEAR)
		tween.set_parallel()
		tween.tween_property(
			marker_sprite,
			"position",
			marker_sprite.position - Vector2.UP.rotated(self.rotation) * 4,
			0.6
		).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	#tween.tween_callback(func(): is_consumed = false)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not is_consumed:
		if body.get_parent() is SwarmDirector:
			GlobalSFX.play_sfx_shuffled(SFX_sap_collected)
			
			collider.call_deferred("set_disabled", true)
			
			var tween = get_tree().create_tween()
			tween.tween_property(
				puddle_mesh,
				"scale:y",
				0,
				0.25
			).set_trans(Tween.TRANS_SINE)
			tween.set_parallel()
			tween.tween_property(
				puddle_mesh,
				"scale:x",
				0.5,
				0.25
			).set_trans(Tween.TRANS_LINEAR)
			for marker in agent_markers.get_children():
				tween.tween_property(
					marker.get_node("SwarmSprite"),
					"modulate",
					Color(0.31, 0.31, 0.31, 0),
					0.1
				).set_trans(Tween.TRANS_LINEAR)
			
			await tween.finished
			is_consumed = true
			#for marker: Marker2D in agent_markers.get_children():
				#GameManager.swarm_director.add_agent(marker.global_position)
			
			

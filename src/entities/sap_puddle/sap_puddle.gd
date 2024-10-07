extends Node2D
class_name SapPuddle

@export var agents_count: int = 5
@export var is_regenerative: bool = false
@export var regen_time: float = 30.0

@export var SFX_sap_collected: Array[AudioStream]

@onready var puddle_mesh := $PuddleMesh
@onready var collider: CollisionPolygon2D = $StaticBody2D/CollisionPolygon2D
@onready var agent_markers_node: Node2D = $AgentMarkers
@onready var agent_marker_scene: PackedScene = preload("res://src/entities/sap_puddle/AgentMarker.tscn")
var is_consumed: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var offset := Vector2(-8.0, -8.0)
	var offset_polygon: PackedVector2Array = collider.polygon * Transform2D(0, offset)
	var random_point_gen := PolygonRandomPointGenerator.new(offset_polygon)
	for agent in agents_count:
		var marker = agent_marker_scene.instantiate()
		var marker_pos := Vector2.INF
		while not Geometry2D.is_point_in_polygon(marker_pos, collider.polygon):
			marker_pos = random_point_gen.get_random_point()
		marker.position = marker_pos
		agent_markers_node.add_child(marker)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func regenerate() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(
		puddle_mesh,
		"scale:y",
		1,
		regen_time
	).set_trans(Tween.TRANS_SINE)
	tween.set_parallel()
	tween.tween_property(
		puddle_mesh,
		"scale:x",
		1,
		regen_time
	).set_trans(Tween.TRANS_LINEAR)
	tween.chain()
	for marker in agent_markers_node.get_children():
		var marker_sprite: Sprite2D = marker.get_node("SwarmSprite")
		tween.tween_property(
			marker_sprite,
			"modulate",
			Color(0.31, 0.31, 0.31, 1),
			0.3
		).set_trans(Tween.TRANS_LINEAR)
		tween.set_parallel()
		tween.tween_property(
			marker_sprite,
			"position",
			marker_sprite.position - Vector2.UP.rotated(self.rotation) * 4,
			0.4
		).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.tween_callback(
		func(): 
			is_consumed = false
	)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not is_consumed:
		if body.get_parent() is SwarmDirector:
			GlobalSFX.play_sfx_shuffled(SFX_sap_collected)
			
			collider.call_deferred("set_disabled", true)
			is_consumed = true
			
			for marker: Marker2D in agent_markers_node.get_children():
				GameManager.swarm_director.add_agent(marker.global_position)
			
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
			for marker in agent_markers_node.get_children():
				tween.tween_property(
					marker.get_node("SwarmSprite"),
					"modulate",
					Color(0.31, 0.31, 0.31, 0),
					0.1
				).set_trans(Tween.TRANS_LINEAR)
			
			await tween.finished
			
			if is_regenerative:
				regenerate()
			else:
				self.queue_free()

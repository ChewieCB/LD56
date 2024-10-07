extends Node2D
class_name SealedGateDoor

@export var SFX_door: Array[AudioStream]

@onready var door_sprite: Sprite2D = $DoorSprite
@onready var door_collider: StaticBody2D = $DoorSprite/StaticBody2D
@onready var frame_sprite: Sprite2D = $FrameSprite
@onready var frame_collider: StaticBody2D = $FrameSprite/StaticBody2D

@onready var door_open_pos: Marker2D = $DoorOpenPos
@onready var door_closed_pos: Marker2D = $DoorClosedPos

@export var is_open: bool = false

func _ready():
	if is_open:
		open()


func open():
	var tween = get_tree().create_tween()
	door_collider.process_mode = Node.PROCESS_MODE_DISABLED
	tween.tween_property(
		door_sprite,
		"position",
		door_open_pos.position,
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	GlobalSFX.play_sfx_shuffled(SFX_door)


func close():
	var tween = get_tree().create_tween()
	tween.tween_property(
		door_sprite,
		"position",
		door_open_pos.position,
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	door_collider.process_mode = Node.PROCESS_MODE_INHERIT
	GlobalSFX.play_sfx_shuffled(SFX_door)

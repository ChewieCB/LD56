extends Node2D
class_name SealedGateDoor

@onready var door_sprite: Sprite2D = $Sprite2D
@onready var static_body: StaticBody2D = $Sprite2D/StaticBody2D

func open():
	door_sprite.visible = false
	static_body.process_mode = Node.PROCESS_MODE_DISABLED

extends Camera2D

@export var target: Node2D

func _process(_delta: float) -> void:
	if target:
		global_position = target.target.global_position

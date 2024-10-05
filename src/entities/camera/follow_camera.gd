extends Camera2D

func _process(_delta: float) -> void:
	if GameManager.player:
		global_position = GameManager.player.global_position

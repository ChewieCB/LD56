extends Button
class_name StyledButton


func _ready() -> void:
	# SFX hooks
	self.mouse_entered.connect(GlobalSFX.play_button_hover_sfx)
	self.pressed.connect(GlobalSFX.play_button_click_sfx)

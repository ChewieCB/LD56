extends Node

@export var button_click_sfx: AudioStream
@export var button_hover_sfx: AudioStream


func play_button_click_sfx() -> void:
	if not button_click_sfx:
		push_error("No AudioStream for button_click_sfx")
		return
	SoundManager.play_sound(button_click_sfx, "SFX")


func play_button_hover_sfx() -> void:
	if not button_hover_sfx:
		push_error("No AudioStream for button_hover_sfx")
		return
	SoundManager.play_sound(button_hover_sfx, "SFX") 

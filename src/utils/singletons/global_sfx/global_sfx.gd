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


func play_sfx_shuffled(
	source_arr: Array[AudioStream], override_bus: String = "", randomize_pitch: bool = false
) -> AudioStreamPlayer:
	if source_arr.is_empty():
		push_warning("No audio streams in sfx array!")
		return
	var shuffled_arr = source_arr.duplicate()
	shuffled_arr.shuffle()
	return SoundManager.play_sound(
		shuffled_arr.pop_front(), override_bus, randomize_pitch
	)


func play_batched_sfx(
	sfx_array: Array[AudioStream], active_players: Array[AudioStreamPlayer],
	max_sfx: int = 50, volume_db: float = 0.0, randomize_pitch: bool = false
) -> void:
	if active_players.size() < max_sfx:
		var sfx_player: AudioStreamPlayer = GlobalSFX.play_sfx_shuffled(
			sfx_array, "", randomize_pitch
		)
		if sfx_player and not is_nan(volume_db):
			sfx_player.finished.connect(func(): active_players.erase(sfx_player))
			active_players.append(sfx_player)
			sfx_player.volume_db = volume_db

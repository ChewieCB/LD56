extends Control
class_name GameUI


@onready var pause_ui: PauseUI = $PauseUI
@onready var victory_screen = $VictoryScreen
@onready var level_stats_label: Label = $VictoryScreen/LevelStatistics
@onready var next_level_button: Button = $VictoryScreen/HBoxContainer/NextButton

func _ready() -> void:
	GameManager.game_ui = self
	victory_screen.visible = false


func show_victory_screen():
	level_stats_label.text = level_stats_label.text.format([
		convert_seconds_to_time_format(GameManager.level_timer),
		GameManager.faes_killed,
		GameManager.enemy_defeated])
	if not GameManager.check_if_next_level_exist():
		next_level_button.visible = false
	victory_screen.visible = true

func convert_seconds_to_time_format(time_in_seconds: float) -> String:
	var total_seconds = int(time_in_seconds) # Convert the float to an integer first
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	var seconds = total_seconds % 60
	return str(hours).pad_zeros(2) + ":" + str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)


func _on_next_button_pressed() -> void:
	SoundManager.play_button_click_sfx()

func _on_title_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	GameManager.go_back_to_title_screen()

func _on_retry_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	GameManager.retry_level()


func play_ui_hover_sound():
	SoundManager.play_button_hover_sfx()

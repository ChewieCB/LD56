extends Control
class_name GameUI


@onready var pause_ui: PauseUI = $PauseUI
@onready var victory_screen = $VictoryScreen
@onready var game_over_screen = $GameOverScreen
@onready var victory_level_stats_label: Label = $VictoryScreen/LevelStatistics
@onready var gameover_level_stats_label: Label = $GameOverScreen/LevelStatistics
@onready var next_level_button: Button = $VictoryScreen/HBoxContainer/NextButton
@onready var agent_count_label: Label = $SwarmAgentCount
@onready var retry_checkpoint_button: Button = $GameOverScreen/HBoxContainer/CheckpointButton

func _ready() -> void:
	GameManager.game_ui = self
	victory_screen.visible = false
	await get_tree().process_frame
	await get_tree().process_frame

func show_victory_screen():
	victory_level_stats_label.text = victory_level_stats_label.text.format([
		convert_seconds_to_time_format(GameManager.level_timer),
		GameManager.faes_killed,
		GameManager.retry_time])
	if not GameManager.check_if_next_level_exist():
		next_level_button.visible = false
	victory_screen.visible = true

func show_game_over_screen():
	gameover_level_stats_label.text = gameover_level_stats_label.text.format([
		convert_seconds_to_time_format(GameManager.level_timer),
		GameManager.faes_killed,
		GameManager.retry_time])
	game_over_screen.visible = true
	if GameManager.checkpoint_activated:
		retry_checkpoint_button.disabled = false
	else:
		retry_checkpoint_button.disabled = true


func update_agent_count_ui():
	agent_count_label.text = "Wisps remaining: {0}".format([GameManager.swarm_director.swarm_agents.size()])

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


func _on_checkpoint_button_pressed() -> void:
	GameManager.retry_last_checkpoint()

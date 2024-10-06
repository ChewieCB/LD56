extends Control
class_name GameUI


@onready var pause_ui: PauseUI = $PauseUI
@onready var victory_screen = $VictoryScreen
@onready var level_stats_label: Label = $VictoryScreen/LevelStatistics

func _ready() -> void:
	GameManager.game_ui = self
	victory_screen.visible = false


func show_victory_screen():
	level_stats_label.text = level_stats_label.text.format([
		GameManager.level_timer,
		GameManager.faes_killed,
		GameManager.enemy_defeated])
	victory_screen.visible = true

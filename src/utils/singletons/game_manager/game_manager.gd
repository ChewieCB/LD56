extends Node

@export var level_list: Array[PackedScene]
@export var title_screen: PackedScene

var player: Player
var pause_ui: PauseUI

# Setting
var fps_limit_index = 2 # From 0 to 5. Refer to EnumAutoload.FPS_LIMIT_ARRAY
var resolution_index = 4 # From 0 to 6. Refer to EnumAutoload.RESOLUTION_ARRAY. Not used in FULL_SCREEN
var vsync_option_index = 1
var window_mode_index = 1 # From 0 to 2
var master_audio = 80
var bgm_audio = 100
var sfx_audio = 100
var ui_audio = 100

func _ready() -> void:
	pass


func load_first_level():
	get_tree().change_scene_to_packed(level_list[0])

func go_back_to_title_screen():
	get_tree().paused = false
	Engine.time_scale = 1
	reset_data()
	get_tree().change_scene_to_packed(title_screen)


func reset_data():
	pass
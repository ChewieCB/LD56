extends Node

@export var level_list: Array[PackedScene]
@export var title_screen: PackedScene

var pause_ui: PauseUI
var game_ui: GameUI
var swarm_director: SwarmDirector

# Setting
var fps_limit_index = 2 # From 0 to 5. Refer to EnumAutoload.FPS_LIMIT_ARRAY
var resolution_index = 4 # From 0 to 6. Refer to EnumAutoload.RESOLUTION_ARRAY. Not used in FULL_SCREEN
var vsync_option_index = 1
var window_mode_index = 1 # From 0 to 2
var master_audio = 80
var bgm_audio = 100
var sfx_audio = 100
var ui_audio = 100
var level_finished = false

# Level stats
var level_timer = 0
var faes_killed = 0
var enemy_defeated = 0

var current_level_id = 0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if not level_finished:
		level_timer += delta

func load_first_level():
	get_tree().change_scene_to_packed(level_list[0])

func go_to_next_level():
	current_level_id += 1
	if current_level_id < level_list.size():
		get_tree().change_scene_to_packed(level_list[current_level_id])

func check_if_next_level_exist():
	return current_level_id + 1 < level_list.size()

func go_back_to_title_screen():
	get_tree().paused = false
	Engine.time_scale = 1
	reset_all_data()
	get_tree().change_scene_to_packed(title_screen)

func finish_level():
	game_ui.show_victory_screen()
	level_finished = true
	get_tree().paused = true


func retry_level():
	reset_level_data()
	get_tree().reload_current_scene()

func reset_level_data():
	level_timer = 0
	faes_killed = 0
	enemy_defeated = 0

func reset_all_data():
	reset_level_data()
	current_level_id = 0

func clean_array(dirty_array: Array) -> Array:
	var cleaned_array = []
	for item in dirty_array:
		if is_instance_valid(item):
			cleaned_array.append(item)
	return cleaned_array

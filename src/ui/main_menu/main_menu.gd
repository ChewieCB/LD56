extends Node2D

@export var animated_buttons: Array[Button] = []

@export var tutorial_node: Control
@export var subtitle_label: RichTextLabel
@export var build_tag_label: Label


var max_tab: int

func _ready() -> void:
	randomize()
	tutorial_node.visible = false
	var subtitle_text: String = get_random_subtitle(
		_read_subtitles_from_file()
	)
	subtitle_label.text = "[left][wave]%s[/wave][/left]" % [subtitle_text]
	build_tag_label.text = BuildTag.VERSION_STRING


func _read_subtitles_from_file() -> PackedStringArray:
	var file := FileAccess.open("res://config/menu_subtitle/menu_subtitle.cfg", FileAccess.READ)
	var possible_subtitles: PackedStringArray = file.get_as_text().split("\n", false)
	file.close()
	return possible_subtitles


func get_random_subtitle(subtitles: PackedStringArray) -> String:
	return subtitles[randi_range(0, subtitles.size() - 1)]


func _on_start_button_pressed() -> void:
	# TODO - change scene to first level
	pass


func _on_tutorial_button_pressed() -> void:
	tutorial_node.visible = !tutorial_node.visible


func _on_quit_button_pressed() -> void:
	get_tree().quit()

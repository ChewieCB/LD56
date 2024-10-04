extends Node

var VERSION_STRING: String = "!! build tag not set !!"


func _ready():
	var file = FileAccess.open("res://config/build_tag/build_tag.cfg", FileAccess.READ)
	VERSION_STRING = file.get_as_text()
	file.close()

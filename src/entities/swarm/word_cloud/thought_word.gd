extends Label
class_name ThoughtWord

var FADE_IN_SPEED = 1
var FADE_OUT_SPEED = 0.5
var FLOAT_SPEED = Vector2(0, -10)

var is_fade_in = true

func _ready():
	modulate.a = 0
	is_fade_in = true

func assign_text(content: String, start_position: Vector2, color: Color = Color.WHITE):
	text = content
	global_position = start_position - (size / 2)
	modulate = color
	modulate.a = 0

func _process(delta):
	global_position += FLOAT_SPEED * delta

	if is_fade_in:
		if modulate.a < 1:
			modulate.a += FADE_IN_SPEED * delta
		else:
			is_fade_in = false
	else:
		if modulate.a > 0:
			modulate.a -= FADE_OUT_SPEED * delta
		else:
			call_deferred("queue_free")
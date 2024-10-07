extends Obstacle

## Whether the field permanently on. This will ignore the electric_interval
@export var always_on = false
## Time between turning electric field on and off
@export var electric_interval = 3.0

@onready var electric_effect: Sprite2D = $Area2D/ElectricEffect
@onready var electric_field_area: Area2D = $Area2D
@onready var lighting_timer: Timer = $LightingTimer

var is_fadeout = false

const FADE_SPEED = 4

func _ready() -> void:
	super()
	is_fadeout = false
	lighting_timer.start(electric_interval)

func _process(delta: float) -> void:
	if is_fadeout:
		# Turn off the electric field
		if electric_effect.modulate.a > 0:
			electric_effect.modulate.a -= FADE_SPEED * delta
		else:
			if electric_field_area.process_mode == Node.PROCESS_MODE_INHERIT:
				electric_field_area.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		# Turn the electric field back on
		if electric_effect.modulate.a < 1:
			electric_effect.modulate.a += FADE_SPEED * delta
		else:
			if electric_field_area.process_mode == Node.PROCESS_MODE_DISABLED:
				electric_field_area.process_mode = Node.PROCESS_MODE_INHERIT


func _on_lighting_fade_timer_timeout() -> void:
	if always_on:
		return
	is_fadeout = not is_fadeout

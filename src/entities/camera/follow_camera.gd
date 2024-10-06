extends Camera2D

@export var target: Node2D
@export var zoom_speed: float = 1.0
var new_zoom_target: Vector2 = zoom


func _ready() -> void:
	var director = target.get_parent()
	if director is SwarmDirector:
		director.close_formation.connect(set_fov.bind(1.25))
		director.normal_formation.connect(set_fov.bind(1.0))
		director.far_formation.connect(set_fov.bind(0.75))


func _physics_process(delta: float) -> void:
	if target:
		global_position = target.global_position
	if zoom != new_zoom_target:
		zoom = zoom.lerp(new_zoom_target, delta * zoom_speed)


func set_fov(value: float) -> void:
	new_zoom_target = Vector2(value, value)

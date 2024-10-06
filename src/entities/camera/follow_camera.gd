extends Camera2D

@export var swarm_director: SwarmDirector
@export var zoom_speed: float = 1.0

var camera_target = null
var new_zoom_target: Vector2 = zoom


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	camera_target = swarm_director.target
	print("CACAC", camera_target)
	if swarm_director is SwarmDirector:
		swarm_director.close_formation.connect(set_fov.bind(1.5))
		swarm_director.normal_formation.connect(set_fov.bind(1.3))
		swarm_director.far_formation.connect(set_fov.bind(0.9))
	set_fov(1.3)


func _physics_process(delta: float) -> void:
	if camera_target:
		global_position = camera_target.global_position
	if zoom != new_zoom_target:
		zoom = zoom.lerp(new_zoom_target, delta * zoom_speed)


func set_fov(value: float) -> void:
	new_zoom_target = Vector2(value, value)

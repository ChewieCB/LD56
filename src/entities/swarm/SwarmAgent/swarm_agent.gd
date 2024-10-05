extends CharacterBody2D
class_name SwarmAgent

@export var target: Marker2D
@export var max_speed: = 200.0
@export var mouse_follow_force: = 0.05
@export var cohesion_force: = 0.05
@export var algin_force: = 0.05
@export var separation_force: = 0.05
@export var view_distance := 50.0
@export var avoid_distance := 20.0

@export var spawn_width: float = 100
@export var spawn_height: float = 100

@onready var agent_collider: CollisionShape2D = $CollisionShape2D
var collision_radius: float:
	set(value):
		collision_radius = value
		agent_collider.shape.radius = collision_radius
@onready var flock_view_collider: CollisionShape2D = $FlockView/CollisionShape2D

var _flock: Array = []
var _mouse_target: Vector2
var _velocity: Vector2


func _ready():
	randomize()
	_velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * max_speed
	flock_view_collider.shape.radius = view_distance


func _physics_process(_delta):
	var mouse_vector = Vector2.ZERO
	if target:
		mouse_vector = global_position.direction_to(target.global_position) * max_speed * mouse_follow_force
	
	# get cohesion, alginment, and separation vectors
	var vectors = get_flock_status(_flock)
	
	# steer towards vectors
	var cohesion_vector = vectors[0] * cohesion_force
	var align_vector = vectors[1] * algin_force
	var separation_vector = vectors[2] * separation_force

	var acceleration = cohesion_vector + align_vector + separation_vector + mouse_vector
	
	_velocity = (_velocity + acceleration).limit_length(max_speed)
	
	set_velocity(_velocity)
	move_and_slide()
	_velocity = velocity


func get_flock_status(flock: Array):
	var center_vector: = Vector2()
	var flock_center: = Vector2()
	var align_vector: = Vector2()
	var avoid_vector: = Vector2()
	
	for f in flock:
		var neighbor_pos: Vector2 = f.global_position

		align_vector += f._velocity
		flock_center += neighbor_pos

		var d = global_position.distance_to(neighbor_pos)
		if d > 0 and d < avoid_distance:
			avoid_vector -= (neighbor_pos - global_position).normalized() * (avoid_distance / d * max_speed)
	
	var flock_size = flock.size()
	if flock_size:
		align_vector /= flock_size
		flock_center /= flock_size

		var center_dir = global_position.direction_to(flock_center)
		var center_speed = max_speed * (global_position.distance_to(flock_center) / $FlockView/ViewRadius.shape.radius)
		center_vector = center_dir * center_speed

	return [center_vector, align_vector, avoid_vector]


func get_random_target():
	randomize()
	return Vector2(randf_range(0, spawn_width), randf_range(0, spawn_height))


func set_collision_radius(radius: float):
	agent_collider.shape.radius =  radius


func _on_flock_view_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		if self != body:
			_flock.append(body)


func _on_flock_view_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_flock.remove_at(_flock.find(body))

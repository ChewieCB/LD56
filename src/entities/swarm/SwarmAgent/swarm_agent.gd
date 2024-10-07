extends CharacterBody2D
class_name SwarmAgent

signal died(agent: SwarmAgent)
signal target_updated(agent: SwarmAgent, new_target: CharacterBody2D)

@export var target: CharacterBody2D:
	set(value):
		target = value
		target_updated.emit(self, target)
@export var max_speed := 200.0
@export var mouse_follow_force := 0.05
@export var cohesion_force := 0.05
@export var algin_force := 0.05
@export var separation_force := 0.05
@export var view_distance := 50.0
@export var avoid_distance := 20.0
@export var state_chart: StateChart
@export var max_health: float = 40.0

@onready var flock_view: Area2D = $FlockView
@onready var flock_view_collider: CollisionShape2D = $FlockView/CollisionShape2D
@export var sprite: Sprite2D
@onready var agent_collider: CollisionShape2D = $CollisionShape2D


var is_in_sealed_vessel = false
var swarm_id: int = 0:
	set(value):
		swarm_id = value
		if swarm_id != 0:
			sprite.modulate = Color.YELLOW
			is_in_sealed_vessel = true
		else:
			sprite.modulate = Color(1, 1, 1)
			is_in_sealed_vessel = false
var is_in_player_swarm: bool = true

var collision_radius: float:
	set(value):
		collision_radius = value
		agent_collider.shape.radius = collision_radius
var current_health: float = max_health:
	set(value):
		current_health = clamp(value, 0, max_health)
		if current_health == 0:
			state_chart.send_event("death")
var _flock: Array = []
var _velocity: Vector2
var target_path: PackedVector2Array:
	set(value):
		target_path = value
		if target_path:
			local_tracking_target = target_path[1]
		#$Line2D.clear_points()
		#for point in target_path:
			#$Line2D.add_point(to_local(point))
			#$Line2D.default_color = Color.RED
			#$Line2D.width = 0.5
var local_tracking_target: Vector2
var is_stored_in_sealed_gate = false

const ARRIVE_DISTANCE = 10.0

func _ready():
	randomize()
	_velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * max_speed
	flock_view_collider.shape.radius = view_distance


func _move_boid() -> void:
	var path_vector = global_position.direction_to(local_tracking_target) * max_speed * mouse_follow_force

	# get cohesion, alginment, and separation vectors
	var vectors = get_flock_status(_flock)

	# steer towards vectors
	var cohesion_vector = vectors[0] * cohesion_force
	var align_vector = vectors[1] * algin_force
	var separation_vector = vectors[2] * separation_force

	var acceleration = cohesion_vector + align_vector + separation_vector + path_vector

	_velocity = (_velocity + acceleration).limit_length(max_speed)

	set_velocity(_velocity)
	move_and_slide()
	_velocity = velocity


func get_flock_status(flock: Array):
	var center_vector := Vector2()
	var flock_center := Vector2()
	var align_vector := Vector2()
	var avoid_vector := Vector2()

	flock = GameManager.clean_array(flock)
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
		var center_speed = max_speed * (global_position.distance_to(flock_center) / flock_view_collider.shape.radius)
		center_vector = center_dir * center_speed

	return [center_vector, align_vector, avoid_vector]


func set_collision_radius(radius: float):
	agent_collider.shape.radius = radius


func damage(value: float) -> void:
	if is_stored_in_sealed_gate:
		return
	if value > 0:
		state_chart.send_event("take_damage")
		current_health -= value


func _on_flock_view_body_entered(body: Node2D) -> void:
	if body is SwarmAgent:
		if self != body:
			if body.swarm_id == self.swarm_id:
				_flock.append(body)


func _on_flock_view_body_exited(body: Node2D) -> void:
	if body is SwarmAgent:
		if body.swarm_id == self.swarm_id:
			var agent_id = _flock.find(body) # Return -1 if not exist
			if agent_id < _flock.size() and agent_id > 0:
				_flock.remove_at(agent_id)


func _on_movement_following_state_physics_processing(_delta: float) -> void:
	_move_boid()


func _on_health_idle_state_entered() -> void:
	sprite.modulate = Color(1, 1, 1)


func _on_health_hurt_state_entered() -> void:
	if current_health > 0:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.2).timeout
		state_chart.send_event("end_damage")


func _on_health_dead_state_entered() -> void:
	state_chart.send_event("disable_movement")
	died.emit(self)
	sprite.modulate = Color.BLACK
	await get_tree().create_timer(0.4).timeout
	GameManager.faes_killed += 1
	call_deferred("queue_free")


func _on_following_state_entered() -> void:
	pass # Replace with function body.

extends CharacterBody2D
class_name Enemy

@export var speed = 100
@export var max_hp = 100

@onready var state_chart: StateChart = $StateChart
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var current_hp = 100
var navigation_initialized = false


func _ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	current_hp = max_hp
	call_deferred("actor_setup")

func actor_setup():
	await get_tree().physics_frame
	await get_tree().physics_frame
	navigation_initialized = true

func _physics_process(_delta: float) -> void:
	if GameManager.player:
		look_at(GameManager.player.global_position)
		nav_agent.target_position = GameManager.player.global_position

	if navigation_initialized:
		var current_position = global_position
		var next_position = nav_agent.get_next_path_position()
		var move_dir = (next_position - current_position).normalized()
		var new_velocity = move_dir * speed
		velocity = new_velocity
		move_and_slide()


func _on_detect_range_body_entered(body: Node2D) -> void:
	if body is Player:
		state_chart.send_event("toTrack")

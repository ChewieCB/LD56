extends CharacterBody2D
class_name Player

@export var speed: float = 200

@onready var sprite: Sprite2D = $Sprite2D

signal change_status

var direction: Vector2 = Vector2.ZERO
var dead = false
var is_fire = false

func _ready():
	GameManager.player = self
	sprite.self_modulate = Color.GREEN


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("player_toggle_fire_status"):
		is_fire = not is_fire
		change_status.emit()
		if is_fire:
			sprite.self_modulate = Color.ORANGE
		else:
			sprite.self_modulate = Color.GREEN

func _process(_delta: float) -> void:
	pass

func _physics_process(_delta):
	if dead:
		return
	direction = Vector2.ZERO
	direction = Input.get_vector("left", "right", "up", "down")

	velocity = direction * speed
	move_and_slide()

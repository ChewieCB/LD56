extends CharacterBody2D
class_name Player

@export var speed: float = 200

var direction: Vector2 = Vector2.ZERO
var dead = false

func _ready():
	GameManager.player = self


func _process(_delta: float) -> void:
	pass

func _physics_process(_delta):
	if dead:
		return
	direction = Vector2.ZERO
	direction = Input.get_vector("left", "right", "up", "down")

	velocity = direction * speed
	move_and_slide()

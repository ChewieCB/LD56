extends CharacterBody2D
class_name Enemy

@export var speed = 100
@export var max_hp = 100

@onready var state_chart: StateChart = $StateChart

var current_hp = 100


func _ready() -> void:
	current_hp = max_hp


func _physics_process(_delta: float) -> void:
	if GameManager.player:
		look_at(GameManager.player.global_position)
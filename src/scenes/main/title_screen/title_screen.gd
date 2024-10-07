extends Control

@onready var title_menu: Control = $TitleMenu
@onready var credit_panel: ColorRect = $CreditPanel
@onready var setting_ui: SettingUI = $SettingUI
@onready var mouse_follow_sprite: Sprite2D = $MouseFollowSprite

const FADE_SPEED = 0.5

func _ready() -> void:
	title_menu.modulate.a = 0
	credit_panel.visible = false
	setting_ui.visible = false

func _process(delta: float) -> void:
	if title_menu.modulate.a < 1:
		title_menu.modulate.a += FADE_SPEED * delta
	make_sprite_follow_mouse(delta)

func _on_start_button_pressed() -> void:
	play_button_click_sfx()
	GameManager.load_first_level()

func _on_setting_button_pressed() -> void:
	play_button_click_sfx()
	setting_ui.visible = !setting_ui.visible
	credit_panel.visible = false

func _on_credit_button_pressed() -> void:
	play_button_click_sfx()
	credit_panel.visible = !credit_panel.visible
	setting_ui.visible = false

func _on_quit_button_pressed() -> void:
	play_button_click_sfx()
	get_tree().quit()

func play_button_hover_sfx():
	SoundManager.play_button_hover_sfx()

func play_button_click_sfx():
	SoundManager.play_button_click_sfx()

func make_sprite_follow_mouse(delta: float):
	var max_speed = 1000.0 # Maximum speed when far from the mouse
	var min_speed = 10.0 # Minimum speed when near the mouse
	var accel_distance = 50.0 # Distance at which acceleration is at max
	var decel_distance = 10.0 # Distance at which deceleration starts
	var accel_factor = 2.0 # Control how fast it accelerates. Smaller is faster
	var decel_factor = 2.0 # Control how fast it decelerates. Smaller is faster

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var sprite_pos: Vector2 = mouse_follow_sprite.global_position
	var distance_to_mouse = sprite_pos.distance_to(mouse_pos)
	var direction_to_mouse = (mouse_pos - sprite_pos).normalized()
	var speed = min_speed
	
	if distance_to_mouse > accel_distance:
		# Accelerate when far
		speed += (distance_to_mouse - accel_distance) / accel_factor
		speed = clamp(speed, min_speed, max_speed)
	elif distance_to_mouse < decel_distance:
		# Decelerate as it gets close to the mouse
		speed += (distance_to_mouse - decel_distance) / decel_factor
		speed = clamp(speed, min_speed, max_speed)

	mouse_follow_sprite.global_position += direction_to_mouse * speed * delta

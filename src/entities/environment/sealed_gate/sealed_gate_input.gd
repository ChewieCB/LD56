extends Node2D
class_name SealedGateInput

@export var n_agent_required = 10
@export var is_disabled: bool = false

# Only 1 of the 2 below is required
@export var sealed_gate_doors: Array[SealedGateDoor]
@export var gate_id: int = 1
@export var is_end_of_level = false

@export var SFX_gate_fill: Array[AudioStream]

@onready var require_label: Label = $Label
@onready var gate_target: CharacterBody2D = $SwarmTarget
@onready var input_area: Area2D = $InputArea
# If no more agent stored during this timer, release all agent to prevent softlock
@onready var release_agent_timer: Timer = $ReleaseAgentTimer

@onready var swarm_director: SwarmDirector = GameManager.swarm_director

const SWARM_ATTRIBUTES_CLOSE: Dictionary = {
	"mouse_follow_force": 0.2,
	"cohesive_force": 0.5,
	"separation_force": 0.5,
	"max_speed": 250,
	"avoid_distance": 5.,
}
const SWARM_ATTRIBUTES_NORMAL: Dictionary = {
	"mouse_follow_force": 0.2,
	"cohesive_force": 0.5,
	"separation_force": 0.5,
	"max_speed": 200,
	"avoid_distance": 15.,
}

var swarm_agent_count: int = 0:
	set(value):
		swarm_agent_count = value
		require_label.text = "{0}/{1}".format([swarm_agent_count, n_agent_required])
		if swarm_agent_count == n_agent_required:
			open_gate()
var swarm_agents: Array = []
var is_fulfilled = false

func _ready() -> void:
	require_label.text = "{0}/{1}".format([swarm_agent_count, n_agent_required])


func _on_input_area_body_entered(body: Node2D) -> void:
	if is_fulfilled or is_disabled:
		return
	if body is SwarmAgent:
		if body.swarm_id == 0:
			var agent: SwarmAgent = body as SwarmAgent
			GlobalSFX.play_sfx_shuffled(SFX_gate_fill)
			if agent not in swarm_agents and swarm_agent_count < n_agent_required:
				# Only follow other nodes in captured flock
				agent.collision_layer = int(pow(2, 9 - 1))
				agent.flock_view.collision_mask = int(pow(2, 9 - 1))
				
				agent.target = gate_target
				agent.swarm_id = gate_id
				
				var agent_idx: int = swarm_director.swarm_agents.find(agent)
				swarm_director.swarms_agents_captured += 1
				swarm_director.swarm_agents.remove_at(agent_idx)
				agent.is_stored_in_sealed_gate = true
				agent.sprite.modulate = Color.YELLOW
				
				swarm_agents.append(agent)
				swarm_agent_count = swarm_agents.size()
				
				set_agent_close(agent)
				
				#var director_swarm_agents = GameManager.swarm_director.swarm_agents
				release_agent_timer.start()


func _physics_process(delta: float) -> void:
	if is_disabled:
		return
	get_nav_path_for_swarm_agents(delta)


func get_nav_path_for_swarm_agents(_delta: float) -> void:
	var nav_map: RID = get_world_2d().get_navigation_map()
	swarm_agents = GameManager.clean_array(swarm_agents)
	for agent in swarm_agents:
		var from_pos: Vector2 = agent.global_position
		var to_pos: Vector2 = agent.target.global_position
		agent.target_path = NavigationServer2D.map_get_path(nav_map, from_pos, to_pos, true)



func set_agent_close(agent: SwarmAgent):
	for key in SWARM_ATTRIBUTES_CLOSE.keys():
		agent.set(key, SWARM_ATTRIBUTES_CLOSE[key])


func set_agent_normal(agent: SwarmAgent):
	for key in SWARM_ATTRIBUTES_NORMAL.keys():
		agent.set(key, SWARM_ATTRIBUTES_NORMAL[key])


func open_gate():
	release_agent_timer.stop()
	is_fulfilled = true
	await get_tree().create_timer(1.6).timeout
	if is_end_of_level:
		GameManager.finish_level()
	else:
		release_all_stored_agents()
		for door in sealed_gate_doors:
			door.open()


func release_all_stored_agents():
	input_area.monitoring = false
	for agent in swarm_agents:
		agent.swarm_id = 0
		swarm_director.swarm_agents.append(agent)
		swarm_director.swarms_agents_captured -= 1
		agent.target = swarm_director.target
		agent.is_stored_in_sealed_gate = false
		# Follow original flock again
		agent.collision_layer = int(pow(2, 2 - 1))
		agent.flock_view.collision_mask = int(pow(2, 1 - 1) + pow(2, 2 - 1))
		set_agent_normal(agent)
		agent.sprite.modulate = Color(1, 1, 1)
		
	swarm_agents = []
	swarm_agent_count = 0
	
	await get_tree().create_timer(3.0).timeout
	input_area.monitoring = true

func _on_release_agent_timer_timeout() -> void:
	if is_disabled:
		return
	if swarm_agent_count < n_agent_required:
		release_all_stored_agents()

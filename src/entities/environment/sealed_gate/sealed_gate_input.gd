extends Node2D
class_name SealedGateInput

@export var n_agent_required = 10

# Only 1 of the 2 below is required
@export var sealed_gate_door: SealedGateDoor
@export var is_end_of_level = false

@onready var require_label: Label = $Label
@onready var gate_target: CharacterBody2D = $SwarmTarget
# If no more agent stored during this timer, release all agent to prevent softlock
@onready var release_agent_timer: Timer = $ReleaseAgentTimer

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
var swarm_agents: Array = []
var is_fulfilled = false

func _ready() -> void:
	require_label.text = "{0}/{1}".format([swarm_agent_count, n_agent_required])


func _on_input_area_body_entered(body: Node2D) -> void:
	if is_fulfilled:
		return
	if body is SwarmAgent:
		var agent: SwarmAgent = body as SwarmAgent
		if agent not in swarm_agents and swarm_agent_count < n_agent_required:
			# Only follow other nodes in captured flock
			agent.collision_layer = int(pow(2, 9 - 1))
			agent.flock_view.collision_mask = int(pow(2, 9 - 1))
			agent.target = gate_target
			agent.is_stored_in_sealed_gate = true
			set_agent_close(agent)
			
			#var director_swarm_agents = GameManager.swarm_director.swarm_agents
			release_agent_timer.start()


func set_agent_close(agent: SwarmAgent):
	for key in SWARM_ATTRIBUTES_CLOSE.keys():
		agent.set(key, SWARM_ATTRIBUTES_CLOSE[key])


func set_agent_normal(agent: SwarmAgent):
	for key in SWARM_ATTRIBUTES_NORMAL.keys():
		agent.set(key, SWARM_ATTRIBUTES_NORMAL[key])


func open_gate():
	release_agent_timer.stop()
	is_fulfilled = true
	if is_end_of_level:
		GameManager.finish_level()
	else:
		release_all_stored_agents()
		sealed_gate_door.open()


func release_all_stored_agents():
	await get_tree().create_timer(5.0).time_out
	for agent in swarm_agents:
		#GameManager.swarm_director.add_agent(agent.position)
		#agent.queue_free()
		agent.target = GameManager.swarm_director.target
		agent.is_stored_in_sealed_gate = false
		# Follow original flock again
		agent.collision_layer = int(pow(2, 2 - 1))
		agent.flock_view.collision_mask = int(pow(2, 1 - 1) + pow(2, 2 - 1))
		set_agent_normal(agent)
	swarm_agents = []
	swarm_agent_count = 0

func _on_release_agent_timer_timeout() -> void:
	if swarm_agent_count < n_agent_required:
		release_all_stored_agents()


func _on_target_area_body_entered(body: Node2D) -> void:
	if body is SwarmAgent:
		if not body in swarm_agents:
			swarm_agents.append(body)
			swarm_agent_count = swarm_agents.size()
			
			if swarm_agent_count >= n_agent_required:
				open_gate()

extends Node2D
class_name SealedGateInput

@export var n_agent_required = 10
@export var sealed_gate_door: SealedGateDoor

@onready var require_label: Label = $Label
@onready var gate_target: CharacterBody2D = $SwarmTarget
# If no more agent stored during this timer, release all agent to prevent softlock
@onready var release_agent_timer: Timer = $ReleaseAgentTimer

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
			release_agent_timer.start()
			agent.target = gate_target
			agent.is_stored_in_sealed_gate = true
			swarm_agents.append(agent)
			swarm_agent_count = swarm_agents.size()
			if swarm_agent_count >= n_agent_required:
				open_gate()


func open_gate():
	release_agent_timer.stop()
	is_fulfilled = true
	release_all_stored_agents()
	sealed_gate_door.open()


func release_all_stored_agents():
	for agent in swarm_agents:
		agent.target = GameManager.swarm_director.target
		agent.is_stored_in_sealed_gate = false
	swarm_agents = []
	swarm_agent_count = 0

func _on_release_agent_timer_timeout() -> void:
	if swarm_agent_count < n_agent_required:
		release_all_stored_agents()

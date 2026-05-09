extends Node

var client: Node
var npc_registry: Dictionary = {}  # server_id -> npc_node
var current_npc: Node = null
var is_connected := false

signal npc_response_received(npc_node: Node, result: Dictionary)
signal connection_status_changed(connected: bool)

func _ready() -> void:
	client = preload("res://addons/ainpcengine/ainpcengine.gd").new()
	add_child(client)
	client.setup(Config.API_URL, Config.API_KEY, Config.GAME_ID)
	_check_connection()

func _check_connection() -> void:
	var health = await client.health()
	if health and health.has("status") and health["status"] == "healthy":
		is_connected = true
		print("[AINPCEngine] Connected to API")
	else:
		is_connected = false
		print("[AINPCEngine] API unreachable — NPCs will appear but cannot respond")
	connection_status_changed.emit(is_connected)

func register_npc(npc_node: Node) -> void:
	var personality = npc_node.get_personality()
	if not is_connected:
		print("[AINPCEngine] Offline — skipping NPC registration for %s" % npc_node.npc_name)
		return

	var request = AINPCModels.create_npc_request(
		personality["name"],
		personality["role"],
		personality["traits"],
		personality["speechStyle"],
		personality["backstory"],
		personality["values"],
		personality["quirks"],
		personality["faction"],
		personality["location"],
		personality.get("inventory", [])
	)
	var result = await client.create_npc(request)
	if result and result.has("id"):
		npc_node.server_npc_id = result["id"]
		npc_registry[result["id"]] = npc_node
		print("[AINPCEngine] Registered NPC: %s -> %s" % [npc_node.npc_name, result["id"]])

func approach_npc(npc_node: Node) -> Dictionary:
	if not is_connected or npc_node.server_npc_id.is_empty():
		return {"response": {"dialogue": "* The NPC stares blankly — no API connection *", "emotion": "neutral"}}
	var ctx = _build_context(npc_node)
	var result = await client.approach(npc_node.server_npc_id, "player_1", ctx)
	if result and result.has("response"):
		npc_response_received.emit(npc_node, result)
	return result if result else {}

func say_to_npc(npc_node: Node, message: String) -> Dictionary:
	if not is_connected or npc_node.server_npc_id.is_empty():
		return {"response": {"dialogue": "* No API connection *", "emotion": "neutral"}}
	var ctx = _build_context(npc_node)
	var result = await client.say(npc_node.server_npc_id, "player_1", message, ctx)
	if result and result.has("response"):
		npc_response_received.emit(npc_node, result)
	return result if result else {}

func request_trade(npc_node: Node, message: String) -> Dictionary:
	if not is_connected or npc_node.server_npc_id.is_empty():
		return {}
	var ctx = _build_context(npc_node)
	var result = await client.request_trade(npc_node.server_npc_id, "player_1", message, ctx)
	if result and result.has("response"):
		npc_response_received.emit(npc_node, result)
	return result if result else {}

func accept_quest(npc_node: Node) -> Dictionary:
	if not is_connected or npc_node.server_npc_id.is_empty():
		return {}
	var ctx = _build_context(npc_node)
	var result = await client.quest_accepted(npc_node.server_npc_id, "player_1", "I accept your quest", ctx)
	if result and result.has("response"):
		npc_response_received.emit(npc_node, result)
	return result if result else {}

func leave_npc(npc_node: Node) -> void:
	if not is_connected or npc_node.server_npc_id.is_empty():
		return
	var ctx = _build_context(npc_node)
	await client.player_left(npc_node.server_npc_id, "player_1", ctx)

func _build_context(npc_node: Node) -> Dictionary:
	var nearby: Array = []
	for id in npc_registry:
		if npc_registry[id] != npc_node:
			nearby.append(npc_registry[id].npc_name)

	var hour = Time.get_time_dict_from_system()["hour"]
	var time_of_day := "night"
	if hour >= 6 and hour < 12:
		time_of_day = "morning"
	elif hour >= 12 and hour < 17:
		time_of_day = "afternoon"
	elif hour >= 17 and hour < 21:
		time_of_day = "evening"

	return AINPCModels.game_context(
		npc_node.npc_location,
		time_of_day,
		"sunny",
		nearby,
		50,
		1,
		[],
		[]
	)

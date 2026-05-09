class_name AINPCEngineClient
extends Node

## AI NPC Engine REST client for Godot 4.
## Add as autoload or instance in your scene tree.
##
## Usage:
##   var client = AINPCEngineClient.new()
##   client.setup("http://localhost:18542", "your-key", "my-game")
##   add_child(client)
##   var result = await client.say(npc_id, "player1", "Hello!", context)

var base_url: String
var api_key: String
var game_id: String

func setup(p_base_url: String, p_api_key: String, p_game_id: String) -> void:
	base_url = p_base_url.rstrip("/")
	api_key = p_api_key
	game_id = p_game_id

# ── NPC CRUD ──────────────────────────────────────────────────────────

func create_npc(request: Dictionary) -> Dictionary:
	return await _post("/api/npcs", request)

func get_npc(npc_id: String) -> Dictionary:
	return await _get("/api/npcs/%s" % npc_id)

func list_npcs() -> Array:
	return await _get("/api/npcs")

func update_npc(npc_id: String, updates: Dictionary) -> Dictionary:
	return await _patch("/api/npcs/%s" % npc_id, updates)

func delete_npc(npc_id: String) -> bool:
	await _delete("/api/npcs/%s" % npc_id)
	return true

# ── Events ────────────────────────────────────────────────────────────

func send_event(npc_id: String, event: Dictionary) -> Dictionary:
	return await _post("/api/npcs/%s/event" % npc_id, event)

func send_batch_events(events: Array) -> Dictionary:
	return await _post("/api/events", {"events": events})

# ── Convenience Event Wrappers ────────────────────────────────────────

func say(npc_id: String, player_id: String, message: String, context: Dictionary) -> Dictionary:
	return await send_event(npc_id, {
		"type": "player_dialogue",
		"playerId": player_id,
		"message": message,
		"context": context
	})

func approach(npc_id: String, player_id: String, context: Dictionary) -> Dictionary:
	return await send_event(npc_id, {
		"type": "player_approached",
		"playerId": player_id,
		"context": context
	})

func request_trade(npc_id: String, player_id: String, message: String, context: Dictionary) -> Dictionary:
	return await send_event(npc_id, {
		"type": "trade_requested",
		"playerId": player_id,
		"message": message,
		"context": context
	})

func start_combat(npc_id: String, player_id: String, context: Dictionary) -> Dictionary:
	return await send_event(npc_id, {
		"type": "combat_started",
		"playerId": player_id,
		"context": context
	})

func combat_ended(npc_id: String, player_id: String, context: Dictionary) -> Dictionary:
	return await send_event(npc_id, {
		"type": "combat_ended",
		"playerId": player_id,
		"context": context
	})

func quest_accepted(npc_id: String, player_id: String, message: String, context: Dictionary) -> Dictionary:
	return await send_event(npc_id, {
		"type": "quest_accepted",
		"playerId": player_id,
		"message": message,
		"context": context
	})

func quest_completed(npc_id: String, player_id: String, message: String, context: Dictionary) -> Dictionary:
	return await send_event(npc_id, {
		"type": "quest_completed",
		"playerId": player_id,
		"message": message,
		"context": context
	})

func quest_failed(npc_id: String, player_id: String, message: String, context: Dictionary) -> Dictionary:
	return await send_event(npc_id, {
		"type": "quest_failed",
		"playerId": player_id,
		"message": message,
		"context": context
	})

func player_left(npc_id: String, player_id: String, context: Dictionary) -> Dictionary:
	return await send_event(npc_id, {
		"type": "player_left",
		"playerId": player_id,
		"context": context
	})

func ambient_trigger(npc_id: String, context: Dictionary) -> Dictionary:
	return await send_event(npc_id, {
		"type": "ambient_trigger",
		"context": context
	})

func world_event(npc_id: String, message: String, context: Dictionary) -> Dictionary:
	return await send_event(npc_id, {
		"type": "world_event",
		"message": message,
		"context": context
	})

func npc_interaction(npc_id: String, other_npc_id: String, message: String, context: Dictionary) -> Dictionary:
	return await send_event(npc_id, {
		"type": "npc_interaction",
		"playerId": other_npc_id,
		"message": message,
		"context": context
	})

# ── Generation ────────────────────────────────────────────────────────

func generate_npc(role: String = "", npc_name: String = "") -> Dictionary:
	var body := {}
	if role != "":
		body["role"] = role
	if npc_name != "":
		body["name"] = npc_name
	return await _post("/api/npcs/generate", body)

func generate_batch(count: int = 5, role: String = "") -> Dictionary:
	var body := {"count": count}
	if role != "":
		body["role"] = role
	return await _post("/api/npcs/generate-batch", body)

# ── Stats / Health ────────────────────────────────────────────────────

func get_stats() -> Dictionary:
	return await _get("/api/stats")

func health() -> Dictionary:
	return await _get("/api/health")

# ── HTTP Helpers ──────────────────────────────────────────────────────

func _get(path: String) -> Variant:
	var http := HTTPRequest.new()
	add_child(http)
	http.request(base_url + path, _headers(), HTTPClient.METHOD_GET)
	var result = await http.request_completed
	http.queue_free()
	return _parse_response(result)

func _post(path: String, body: Dictionary) -> Variant:
	var http := HTTPRequest.new()
	add_child(http)
	var json_body := JSON.stringify(body)
	http.request(base_url + path, _headers(), HTTPClient.METHOD_POST, json_body)
	var result = await http.request_completed
	http.queue_free()
	return _parse_response(result)

func _patch(path: String, body: Dictionary) -> Variant:
	var http := HTTPRequest.new()
	add_child(http)
	var json_body := JSON.stringify(body)
	http.request(base_url + path, _headers(), HTTPClient.METHOD_PATCH, json_body)
	var result = await http.request_completed
	http.queue_free()
	return _parse_response(result)

func _delete(path: String) -> Variant:
	var http := HTTPRequest.new()
	add_child(http)
	http.request(base_url + path, _headers(), HTTPClient.METHOD_DELETE)
	var result = await http.request_completed
	http.queue_free()
	return _parse_response(result)

func _headers() -> PackedStringArray:
	return PackedStringArray([
		"Content-Type: application/json",
		"x-api-key: %s" % api_key,
		"x-game-id: %s" % game_id,
	])

func _parse_response(result: Array) -> Variant:
	var response_code: int = result[1]
	var body: PackedByteArray = result[3]
	var text := body.get_string_from_utf8()
	if text == "":
		return {}
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("AINPCEngine: Failed to parse response: %s" % text)
		return {}
	return parsed

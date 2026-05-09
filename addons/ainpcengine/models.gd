class_name AINPCModels
extends RefCounted

## Helper functions to build request dictionaries for the AINPCEngine API.
## These are optional convenience builders — you can also pass raw Dictionaries.

static func create_npc_request(
	npc_name: String,
	role: String,
	traits: Array = [],
	speech_style: String = "",
	backstory: String = "",
	values: Array = [],
	quirks: Array = [],
	faction: String = "",
	location: String = "",
	inventory: Array = []
) -> Dictionary:
	var req := {
		"name": npc_name,
		"role": role,
		"personality": {
			"traits": traits,
			"speechStyle": speech_style,
			"backstory": backstory,
			"values": values,
			"quirks": quirks,
		}
	}
	if faction != "":
		req["faction"] = faction
	if location != "":
		req["location"] = location
	if inventory.size() > 0:
		req["inventory"] = inventory
	return req

static func game_context(
	location: String = "",
	time_of_day: String = "",
	weather: String = "",
	nearby_npcs: Array = [],
	player_reputation: int = 0,
	player_level: int = 0,
	active_quests: Array = [],
	recent_events: Array = []
) -> Dictionary:
	return {
		"location": location,
		"timeOfDay": time_of_day,
		"weather": weather,
		"nearbyNPCs": nearby_npcs,
		"playerReputation": player_reputation,
		"playerLevel": player_level,
		"activeQuests": active_quests,
		"recentEvents": recent_events,
	}

static func game_event(
	type: String,
	player_id: String = "",
	message: String = "",
	context: Dictionary = {}
) -> Dictionary:
	var evt := {"type": type, "context": context}
	if player_id != "":
		evt["playerId"] = player_id
	if message != "":
		evt["message"] = message
	return evt

static func inventory_item(item_name: String, price: int, quantity: int = 1) -> Dictionary:
	return {"item": item_name, "price": price, "quantity": quantity}

static func batch_event(
	type: String,
	npc_id: String,
	player_id: String = "",
	message: String = "",
	context: Dictionary = {}
) -> Dictionary:
	var evt := {"type": type, "npcId": npc_id, "context": context}
	if player_id != "":
		evt["playerId"] = player_id
	if message != "":
		evt["message"] = message
	return evt

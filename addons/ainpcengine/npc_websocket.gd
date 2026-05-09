class_name AINPCWebSocket
extends Node

## WebSocket client for real-time NPC event streaming in Godot 4.
##
## Usage:
##   var ws = AINPCWebSocket.new()
##   add_child(ws)
##   ws.response_received.connect(_on_npc_response)
##   ws.connect_to_server("ws://localhost:18542/ws", "key", "my-game")

signal response_received(result: Dictionary)
signal connected()
signal disconnected(reason: String)
signal error_received(message: String)

var _socket := WebSocketPeer.new()
var _is_connected := false

func connect_to_server(base_url: String, api_key: String, game_id: String) -> void:
	var url := "%s?apiKey=%s&gameId=%s" % [base_url, api_key, game_id]
	var err := _socket.connect_to_url(url)
	if err != OK:
		error_received.emit("Failed to connect: error code %d" % err)

func disconnect_from_server() -> void:
	if _is_connected:
		_socket.close()
		_is_connected = false

func is_connected_to_server() -> bool:
	return _is_connected

func send_event(npc_id: String, event_data: Dictionary) -> void:
	if not _is_connected:
		return
	var data := event_data.duplicate()
	data["npcId"] = npc_id
	var msg := {"action": "event", "data": data}
	_socket.send_text(JSON.stringify(msg))

func subscribe(npc_ids: Array) -> void:
	if not _is_connected:
		return
	var msg := {"action": "subscribe", "npcIds": npc_ids}
	_socket.send_text(JSON.stringify(msg))

func unsubscribe(npc_ids: Array) -> void:
	if not _is_connected:
		return
	var msg := {"action": "unsubscribe", "npcIds": npc_ids}
	_socket.send_text(JSON.stringify(msg))

func _process(_delta: float) -> void:
	_socket.poll()

	var state := _socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not _is_connected:
			_is_connected = true
			connected.emit()
		while _socket.get_available_packet_count() > 0:
			var packet := _socket.get_packet()
			var text := packet.get_string_from_utf8()
			_handle_message(text)
	elif state == WebSocketPeer.STATE_CLOSED:
		if _is_connected:
			_is_connected = false
			var code := _socket.get_close_code()
			var reason := _socket.get_close_reason()
			disconnected.emit("Code %d: %s" % [code, reason])
			set_process(false)

func _handle_message(text: String) -> void:
	var parsed = JSON.parse_string(text)
	if parsed == null:
		error_received.emit("Failed to parse message: %s" % text)
		return

	var type: String = parsed.get("type", "")

	if type == "response":
		var data = parsed.get("data", {})
		if data:
			response_received.emit(data)
	elif type == "error":
		var msg: String = parsed.get("message", "Unknown error")
		error_received.emit("Server error: %s" % msg)

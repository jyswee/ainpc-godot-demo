extends PanelContainer

var current_npc: Node = null
var typewriter_timer: Timer
var pending_text: String = ""
var displayed_text: String = ""
var char_index: int = 0

@onready var portrait: ColorRect = %Portrait
@onready var npc_name_label: Label = %NPCName
@onready var npc_role_label: Label = %NPCRole
@onready var dialogue_text: RichTextLabel = %DialogueText
@onready var player_input: LineEdit = %PlayerInput
@onready var send_btn: Button = %SendBtn
@onready var trade_btn: Button = %TradeBtn
@onready var quest_btn: Button = %QuestBtn
@onready var close_btn: Button = %CloseBtn
@onready var emotion_color: ColorRect = %EmotionColor
@onready var emotion_label: Label = %EmotionLabel
@onready var mood_bar: ProgressBar = %MoodBar

func _ready() -> void:
	add_to_group("dialogue_panel")
	visible = false

	typewriter_timer = Timer.new()
	typewriter_timer.wait_time = 0.03
	typewriter_timer.timeout.connect(_on_typewriter_tick)
	add_child(typewriter_timer)

	send_btn.pressed.connect(_on_send_pressed)
	trade_btn.pressed.connect(_on_trade_pressed)
	quest_btn.pressed.connect(_on_quest_pressed)
	close_btn.pressed.connect(_on_close_pressed)
	player_input.text_submitted.connect(_on_text_submitted)

	GameManager.npc_response_received.connect(_on_npc_response)

func open_for_npc(npc: Node) -> void:
	current_npc = npc
	visible = true

	# Set NPC info
	portrait.color = npc.npc_color
	npc_name_label.text = npc.npc_name
	npc_role_label.text = npc.role.capitalize()

	# Show/hide context buttons
	trade_btn.visible = npc.role == "merchant"
	quest_btn.visible = npc.role == "quest_giver"

	# Clear dialogue
	dialogue_text.text = ""
	player_input.text = ""
	update_emotion(npc.current_emotion, npc.emotion_intensity)

	# Send approach event
	_add_system_text("* You approach %s *" % npc.npc_name)
	var result = await GameManager.approach_npc(npc)
	if result and result.has("response"):
		_handle_response(result["response"])

	player_input.grab_focus()

func close_panel() -> void:
	visible = false
	current_npc = null
	typewriter_timer.stop()

func update_emotion(emotion: String, intensity: float) -> void:
	var color = current_npc.EMOTION_COLORS.get(emotion.to_lower(), Color.GRAY) if current_npc else Color.GRAY
	emotion_color.color = color
	emotion_label.text = emotion.capitalize()
	mood_bar.value = intensity * 100.0

func _handle_response(response: Dictionary) -> void:
	var dialogue = response.get("dialogue", "...")
	var emotion = response.get("emotion", "neutral")
	var intensity = 0.5

	# Update NPC emotion
	if current_npc:
		current_npc.set_emotion(emotion, intensity)
	update_emotion(emotion, intensity)

	# Show NPC action if present
	var action = response.get("action", {})
	if action and action is Dictionary and action.has("type"):
		_add_system_text("* %s %s *" % [current_npc.npc_name if current_npc else "NPC", action.get("type", "")])

	# Show trade offer if present
	var trade = response.get("tradeOffer", {})
	if trade and trade is Dictionary and trade.has("item"):
		_add_system_text("* Offers: %s for %s gold *" % [trade["item"], trade.get("price", "?")])

	# Show quest update if present
	var quest = response.get("questUpdate", {})
	if quest and quest is Dictionary and quest.has("questId"):
		_add_system_text("* Quest: %s — %s *" % [quest.get("status", ""), quest.get("nextObjective", "")])

	# Typewriter effect for dialogue
	_start_typewriter("[color=#ffd700]%s:[/color] %s" % [current_npc.npc_name if current_npc else "NPC", dialogue])

func _start_typewriter(text: String) -> void:
	pending_text = text
	displayed_text = ""
	char_index = 0
	typewriter_timer.start()

func _on_typewriter_tick() -> void:
	if char_index < pending_text.length():
		# Skip BBCode tags instantly
		if pending_text[char_index] == "[":
			var close = pending_text.find("]", char_index)
			if close != -1:
				displayed_text += pending_text.substr(char_index, close - char_index + 1)
				char_index = close + 1
			else:
				displayed_text += pending_text[char_index]
				char_index += 1
		else:
			displayed_text += pending_text[char_index]
			char_index += 1
		# Update the last line in dialogue
		var lines = dialogue_text.text.split("\n")
		if lines.size() > 0 and not lines[-1].begins_with("[i]"):
			lines[-1] = displayed_text
		else:
			lines.append(displayed_text)
		dialogue_text.text = "\n".join(lines)
	else:
		typewriter_timer.stop()

func _add_system_text(text: String) -> void:
	if dialogue_text.text.length() > 0:
		dialogue_text.text += "\n"
	dialogue_text.text += "[i]%s[/i]" % text

func _add_player_text(text: String) -> void:
	if dialogue_text.text.length() > 0:
		dialogue_text.text += "\n"
	dialogue_text.text += "[color=#87ceeb]You:[/color] %s" % text

func _on_send_pressed() -> void:
	_send_message()

func _on_text_submitted(_text: String) -> void:
	_send_message()

func _send_message() -> void:
	var msg = player_input.text.strip_edges()
	if msg.is_empty() or not current_npc:
		return

	player_input.text = ""
	_add_player_text(msg)

	send_btn.disabled = true
	var result = await GameManager.say_to_npc(current_npc, msg)
	send_btn.disabled = false

	if result and result.has("response"):
		_handle_response(result["response"])

	player_input.grab_focus()

func _on_trade_pressed() -> void:
	if not current_npc:
		return
	_add_system_text("* You request to trade *")
	trade_btn.disabled = true
	var result = await GameManager.request_trade(current_npc, "I'd like to see your wares")
	trade_btn.disabled = false
	if result and result.has("response"):
		_handle_response(result["response"])

func _on_quest_pressed() -> void:
	if not current_npc:
		return
	_add_system_text("* You accept the quest *")
	quest_btn.disabled = true
	var result = await GameManager.accept_quest(current_npc)
	quest_btn.disabled = false
	if result and result.has("response"):
		_handle_response(result["response"])

func _on_close_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player._close_dialogue()

func _on_npc_response(npc_node: Node, _result: Dictionary) -> void:
	if npc_node == current_npc:
		pass  # Already handled via direct await

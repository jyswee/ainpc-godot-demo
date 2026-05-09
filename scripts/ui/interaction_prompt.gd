extends Label

var player: Node = null

func _ready() -> void:
	visible = false
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _process(_delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	if player.is_in_dialogue:
		visible = false
		return

	if player.nearest_npc:
		text = "Press E to talk to %s" % player.nearest_npc.npc_name
		visible = true
	else:
		visible = false

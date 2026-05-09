extends CharacterBody3D

const SPEED := 5.0
const MOUSE_SENSITIVITY := 0.002

var nearest_npc: Node = null
var is_in_dialogue := false

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not is_in_dialogue:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI / 3, PI / 3)

	if event.is_action_pressed("interact") and not is_in_dialogue:
		if nearest_npc:
			_interact_with_npc(nearest_npc)

	if event.is_action_pressed("ui_cancel") and is_in_dialogue:
		_close_dialogue()

func _physics_process(_delta: float) -> void:
	if is_in_dialogue:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	input_dir = input_dir.normalized()

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Gravity
	if not is_on_floor():
		velocity.y -= 9.8 * _delta

	move_and_slide()

func set_nearest_npc(npc: Node) -> void:
	nearest_npc = npc

func clear_nearest_npc(npc: Node) -> void:
	if nearest_npc == npc:
		nearest_npc = null

func _interact_with_npc(npc: Node) -> void:
	is_in_dialogue = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var dialogue_panel = get_tree().get_first_node_in_group("dialogue_panel")
	if dialogue_panel:
		dialogue_panel.open_for_npc(npc)

func _close_dialogue() -> void:
	is_in_dialogue = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var dialogue_panel = get_tree().get_first_node_in_group("dialogue_panel")
	if dialogue_panel:
		if dialogue_panel.current_npc:
			GameManager.leave_npc(dialogue_panel.current_npc)
		dialogue_panel.close_panel()

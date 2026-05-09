extends CharacterBody3D

@export var npc_name: String = "NPC"
@export var role: String = "villager"
@export var npc_color: Color = Color.GRAY
@export var npc_location: String = "village_square"

var server_npc_id: String = ""
var current_emotion: String = "neutral"
var emotion_intensity: float = 0.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var name_label: Label3D = $NameLabel
@onready var emotion_orb: MeshInstance3D = $EmotionOrb

const EMOTION_COLORS := {
	"neutral": Color(0.6, 0.6, 0.6),
	"happy": Color(1.0, 0.9, 0.2),
	"angry": Color(0.9, 0.15, 0.15),
	"sad": Color(0.2, 0.3, 0.9),
	"fearful": Color(0.6, 0.2, 0.8),
	"curious": Color(0.2, 0.8, 0.8),
	"suspicious": Color(0.9, 0.5, 0.1),
	"grateful": Color(0.2, 0.8, 0.3),
	"amused": Color(1.0, 0.7, 0.3),
	"disgusted": Color(0.5, 0.4, 0.1),
	"excited": Color(1.0, 0.4, 0.7),
	"contempt": Color(0.5, 0.2, 0.2),
}

func _ready() -> void:
	# Set NPC body color
	var mat = StandardMaterial3D.new()
	mat.albedo_color = npc_color
	mesh.material_override = mat

	# Set name label
	name_label.text = "%s\n%s" % [npc_name, role.capitalize()]

	# Set initial emotion orb
	_update_emotion_orb()

	# Register with game manager
	GameManager.register_npc(self)

func _on_interaction_zone_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.set_nearest_npc(self)

func _on_interaction_zone_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.clear_nearest_npc(self)

func set_emotion(emotion: String, intensity: float = 0.5) -> void:
	current_emotion = emotion.to_lower()
	emotion_intensity = clamp(intensity, 0.0, 1.0)
	_update_emotion_orb()

func _update_emotion_orb() -> void:
	if not emotion_orb:
		return
	var color = EMOTION_COLORS.get(current_emotion, EMOTION_COLORS["neutral"])
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5 + emotion_intensity
	emotion_orb.material_override = mat

func get_personality() -> Dictionary:
	match role:
		"merchant":
			return {
				"name": npc_name,
				"role": role,
				"traits": ["shrewd", "friendly", "cunning", "silver-tongued"],
				"speechStyle": "Enthusiastic medieval trader, uses coin metaphors, always upselling",
				"backstory": "Once a travelling merchant who settled in the village after her caravan was attacked. Now runs the market stall, always looking for a good deal.",
				"values": ["profit", "fairness", "community"],
				"quirks": ["rubs coins together when nervous", "winks when offering a deal"],
				"faction": "Merchants Guild",
				"location": npc_location,
				"inventory": [
					AINPCModels.inventory_item("Health Potion", 50, 10),
					AINPCModels.inventory_item("Iron Sword", 150, 3),
					AINPCModels.inventory_item("Mystery Map", 500, 1),
				]
			}
		"guard":
			return {
				"name": npc_name,
				"role": role,
				"traits": ["stoic", "dutiful", "suspicious", "protective"],
				"speechStyle": "Clipped military speech, formal address, rarely jokes",
				"backstory": "A veteran soldier who retired to guard duty after a knee injury. Takes his post very seriously and trusts no one at first.",
				"values": ["order", "duty", "honor"],
				"quirks": ["constantly scans the perimeter", "hand always near sword hilt"],
				"faction": "Village Watch",
				"location": npc_location,
			}
		"quest_giver":
			return {
				"name": npc_name,
				"role": role,
				"traits": ["mysterious", "wise", "cryptic", "patient"],
				"speechStyle": "Speaks in riddles and half-truths, references prophecies, dramatic pauses",
				"backstory": "An elderly seer who has lived in the village longer than anyone can remember. She posts quests on the village board and seems to know things she shouldn't.",
				"values": ["knowledge", "balance", "destiny"],
				"quirks": ["eyes glow faintly when giving quests", "hums an unknown melody"],
				"faction": "Seers Circle",
				"location": npc_location,
			}
		_:
			return {
				"name": npc_name,
				"role": role,
				"traits": ["friendly"],
				"speechStyle": "casual",
				"backstory": "A villager.",
				"values": ["community"],
				"quirks": [],
				"faction": "",
				"location": npc_location,
			}

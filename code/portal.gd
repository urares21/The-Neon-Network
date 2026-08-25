extends Area3D
# ============================================================
# Portal.gd — Portal către următorul server (next level)
# Se activează DOAR când jucătorul a strâns destule chei.
# ============================================================

@export var required_keys: int = 3
@export var next_scene: String = "res://scenes/Level02.tscn"
@export var inactive_material: Material
@export var active_material: Material

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var prompt_label: Label3D = $PromptLabel  # text "PORTAL LOCKED – 0/3 KEYS"

var active: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_refresh_state()
	# Conectează la semnalul jucătorului (ascultăm când strânge chei)
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("keys_changed"):
		player.keys_changed.connect(_on_keys_changed)

func _on_keys_changed(count: int) -> void:
	active = count >= required_keys
	_refresh_state()

func _refresh_state() -> void:
	if active:
		mesh.material_override = active_material
		prompt_label.text = "ENTER PORTAL → NEXT SERVER"
	else:
		mesh.material_override = inactive_material
		var player = get_tree().get_first_node_in_group("player")
		var k: int = 0 if player == null else player.access_keys_collected
		prompt_label.text = "PORTAL LOCKED – %d/%d KEYS" % [k, required_keys]

func _on_body_entered(body: Node) -> void:
	if not active: return
	if body.is_in_group("player"):
		get_tree().call_group("game_manager", "on_level_complete", next_scene)

extends Area3D
# Teleporter — paired Area3Ds. Stepping on one warps you to the linked one.

@export var target: NodePath
@export var cooldown_seconds: float = 1.5

var cooldown: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	cooldown = max(cooldown - delta, 0.0)

func _on_body_entered(body: Node) -> void:
	if cooldown > 0.0: return
	if not body.is_in_group("player"): return
	if target.is_empty(): return
	var t: Node3D = get_node_or_null(target)
	if t == null: return
	# Block re-trigger on the target side momentarily
	cooldown = cooldown_seconds
	if "cooldown" in t:
		t.cooldown = cooldown_seconds
	body.global_position = t.global_position + Vector3(0, 0.5, 0)
	# Pickup sound
	var stream = load("res://audio/pickup.wav")
	if stream:
		var p := AudioStreamPlayer.new()
		p.stream = stream
		p.pitch_scale = 1.6
		get_tree().current_scene.add_child(p)
		p.play()
		p.finished.connect(p.queue_free)

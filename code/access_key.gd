extends Area3D
# ============================================================
# AccessKey.gd — Pickup "Cheie de Acces"
# Structura: Area3D + CollisionShape3D + MeshInstance3D (model cu shader neon)
# Animație: rotație continuă + plutire (idle hover)
# ============================================================

@export var rotation_speed: float = 1.5
@export var hover_amplitude: float = 0.15
@export var hover_speed: float = 2.0

var base_y: float
var time_alive: float = 0.0

func _ready() -> void:
	base_y = global_position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	time_alive += delta
	rotate_y(rotation_speed * delta)
	# Plutire sinusoidală
	global_position.y = base_y + sin(time_alive * hover_speed) * hover_amplitude

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("collect_key"):
		body.collect_key()
		_play_pickup_sound()
		queue_free()

func _play_pickup_sound() -> void:
	var stream = load("res://audio/pickup.wav")
	if stream == null: return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = -2.0
	get_tree().current_scene.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

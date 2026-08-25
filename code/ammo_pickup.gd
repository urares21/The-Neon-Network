extends Area3D
# AmmoPickup — gives the player +X ammo on touch.

@export var ammo_amount: int = 6
@export var rotation_speed: float = 1.5
@export var hover_amplitude: float = 0.12
@export var hover_speed: float = 2.5

var base_y: float
var time_alive: float = 0.0

func _ready() -> void:
	base_y = global_position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	time_alive += delta
	rotate_y(rotation_speed * delta)
	global_position.y = base_y + sin(time_alive * hover_speed) * hover_amplitude

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("collect_ammo"):
		body.collect_ammo(ammo_amount)
		var stream = load("res://audio/pickup.wav")
		if stream:
			var p := AudioStreamPlayer.new()
			p.stream = stream
			p.volume_db = -4.0
			p.pitch_scale = 1.3  # slightly higher pitch than key pickup
			get_tree().current_scene.add_child(p)
			p.play()
			p.finished.connect(p.queue_free)
		queue_free()

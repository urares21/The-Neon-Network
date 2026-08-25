extends Area3D
# HealthPickup — restores player HP when collected.

@export var heal_amount: int = 35
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
	global_position.y = base_y + sin(time_alive * hover_speed) * hover_amplitude

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and "current_health" in body:
		if body.current_health < body.max_health:
			body.current_health = min(body.current_health + heal_amount, body.max_health)
			body.emit_signal("health_changed", body.current_health)
			# Pickup sound
			var stream = load("res://audio/pickup.wav")
			if stream:
				var p := AudioStreamPlayer.new()
				p.stream = stream
				p.pitch_scale = 0.8
				get_tree().current_scene.add_child(p)
				p.play()
				p.finished.connect(p.queue_free)
			queue_free()

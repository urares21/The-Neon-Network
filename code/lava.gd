extends Area3D
# Lava — damages the player over time while inside.
# Visual: pulsing emissive orange/red plane.

@export var damage_per_tick: int = 8
@export var tick_interval: float = 0.5

var player_inside: Node = null
var time_to_tick: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if player_inside == null: return
	time_to_tick -= delta
	if time_to_tick <= 0.0:
		time_to_tick = tick_interval
		if player_inside.has_method("take_damage"):
			player_inside.take_damage(damage_per_tick)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = body
		time_to_tick = 0.0  # immediate first tick

func _on_body_exited(body: Node) -> void:
	if body == player_inside:
		player_inside = null

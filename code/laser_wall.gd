extends Area3D
# LaserWall — toggling electric barrier. Damages on contact while active.

@export var damage_per_tick: int = 12
@export var tick_interval: float = 0.3
@export var on_duration: float = 1.6     # how long laser is ACTIVE
@export var off_duration: float = 1.2    # how long laser is OFF (safe to pass)
@export var initial_state_active: bool = true

@onready var mesh: MeshInstance3D = $LaserMesh
@onready var glow_light: OmniLight3D = $GlowLight

var is_active: bool
var time_to_toggle: float
var player_inside: Node = null
var time_to_tick: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	is_active = initial_state_active
	_apply_visual()
	time_to_toggle = on_duration if is_active else off_duration

func _process(delta: float) -> void:
	# Toggle on/off
	time_to_toggle -= delta
	if time_to_toggle <= 0.0:
		is_active = not is_active
		time_to_toggle = on_duration if is_active else off_duration
		_apply_visual()
	# Damage tick when active and player inside
	if is_active and player_inside:
		time_to_tick -= delta
		if time_to_tick <= 0.0:
			time_to_tick = tick_interval
			if player_inside.has_method("take_damage"):
				player_inside.take_damage(damage_per_tick)

func _apply_visual() -> void:
	if is_active:
		if mesh: mesh.visible = true
		if glow_light: glow_light.light_energy = 6.0
		monitoring = true
	else:
		if mesh: mesh.visible = false
		if glow_light: glow_light.light_energy = 0.0
		monitoring = false
		player_inside = null

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = body
		time_to_tick = 0.0

func _on_body_exited(body: Node) -> void:
	if body == player_inside:
		player_inside = null

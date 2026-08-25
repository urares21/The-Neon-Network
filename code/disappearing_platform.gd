extends AnimatableBody3D
# Touch-activated. Starts solid; when player steps on it, count down trigger_delay,
# then disappear for hidden_duration, then reappear.

@export var trigger_delay: float = 2.0
@export var hidden_duration: float = 3.0

@onready var mesh: MeshInstance3D = $M
@onready var coll: CollisionShape3D = $C
@onready var trigger: Area3D = $Trigger
@onready var glow: OmniLight3D = get_node_or_null("Glow")

enum State { SOLID, DISSOLVING, HIDDEN }
var state: int = State.SOLID
var timer: float = 0.0

func _ready() -> void:
	trigger.body_entered.connect(_on_step)
	_apply_solid()

func _process(delta: float) -> void:
	if state == State.DISSOLVING:
		timer -= delta
		# Flash glow as warning
		if glow:
			var f: float = max(timer / trigger_delay, 0.0)
			glow.light_energy = 2.5 + (1.0 - f) * 6.0
			glow.light_color = Color(1, 0.5 * f, 0.5 * f, 1)
		if timer <= 0.0:
			state = State.HIDDEN
			_apply_hidden()
			timer = hidden_duration
	elif state == State.HIDDEN:
		timer -= delta
		if timer <= 0.0:
			state = State.SOLID
			_apply_solid()

func _on_step(body: Node) -> void:
	if state == State.SOLID and body.is_in_group("player"):
		state = State.DISSOLVING
		timer = trigger_delay

func _apply_solid() -> void:
	mesh.visible = true
	coll.disabled = false
	if glow:
		glow.light_energy = 2.5
		glow.light_color = Color(0, 0.9, 1, 1)

func _apply_hidden() -> void:
	mesh.visible = false
	coll.disabled = true
	if glow:
		glow.light_energy = 0.0

extends AnimatableBody3D
# MovingPlatform — slides back and forth between origin and origin + travel_offset.
# AnimatableBody3D moves the player correctly when they stand on it.

@export var travel_offset: Vector3 = Vector3(0, 0, 6)
@export var period: float = 4.0   # full back-and-forth in seconds
@export var phase: float = 0.0    # 0..1 stagger multiple platforms
@export var initial_delay: float = 0.0  # wait this many seconds before moving

var time_elapsed: float
var origin: Vector3
var delay_remaining: float

func _ready() -> void:
	origin = position
	time_elapsed = phase * period
	delay_remaining = initial_delay

func _physics_process(delta: float) -> void:
	if delay_remaining > 0.0:
		delay_remaining -= delta
		return
	time_elapsed += delta
	var t: float = 0.5 - 0.5 * cos(TAU * time_elapsed / period)
	position = origin + travel_offset * t

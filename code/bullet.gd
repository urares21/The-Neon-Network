extends Area3D
# Bullet — projectile used by both player and turrets.
# Set owner_group so the bullet doesn't hurt its faction.

@export var speed: float = 45.0
@export var damage: int = 25
@export var lifetime: float = 2.5
@export var owner_group: String = "player"  # set "enemies" for turret bullets

var direction: Vector3 = Vector3.FORWARD
var alive_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	# If we spawned INSIDE a body (e.g. point-blank boss), trigger on next physics tick
	call_deferred("_check_initial_overlap")

func _check_initial_overlap() -> void:
	if not is_inside_tree(): return
	for body in get_overlapping_bodies():
		_on_body_entered(body)
		if not is_inside_tree(): return

func launch(dir: Vector3) -> void:
	direction = dir.normalized()
	look_at(global_position + direction, Vector3.UP)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	alive_time += delta
	if alive_time >= lifetime:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if owner_group != "" and body.is_in_group(owner_group):
		return  # don't hit own faction
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func _on_area_entered(area: Area3D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()

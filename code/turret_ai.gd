extends StaticBody3D
# ============================================================
# TurretAI — stationary enemy that aims at the player and shoots projectiles.
# Doesn't move. FSM: IDLE -> AIM -> SHOOT -> DEAD
# ============================================================

@export var max_health: int = 50
@export var sight_range: float = 25.0
@export var aim_speed: float = 2.5            # rad/s
@export var fire_interval: float = 1.6
@export var bullet_scene: PackedScene
@export var ammo_pickup_scene: PackedScene
@export var drop_chance: float = 0.9

@onready var turret_head: Node3D = $TurretHead
@onready var muzzle: Marker3D = $TurretHead/Muzzle
@onready var fire_timer: Timer = $FireTimer
@onready var muzzle_light: OmniLight3D = get_node_or_null("TurretHead/Muzzle/MuzzleLight")

var current_health: int
var player: Node3D = null
var is_dead: bool = false

func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")
	fire_timer.wait_time = fire_interval
	fire_timer.timeout.connect(_try_fire)
	fire_timer.start()
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if is_dead or player == null: return

	var to_player = player.global_position - turret_head.global_position
	var dist = to_player.length()
	if dist > sight_range: return

	# Use look_at: makes turret head's -Z point at the player (correct forward direction).
	# We aim at the player's chest (~1m above feet) so projectiles fly horizontally.
	var target_pos := player.global_position + Vector3.UP * 1.0
	# Avoid degenerate case (target on the same vertical axis)
	if target_pos.distance_to(turret_head.global_position) > 0.05:
		var cur_t := turret_head.global_transform
		var desired_t := cur_t.looking_at(target_pos, Vector3.UP)
		var current_q := cur_t.basis.get_rotation_quaternion()
		var desired_q := desired_t.basis.get_rotation_quaternion()
		var t: float = clamp(aim_speed * delta, 0.0, 1.0)
		var new_q := current_q.slerp(desired_q, t)
		# Reassign full transform — modifying .basis on global_transform directly
		# doesn't persist because the property returns a copy.
		turret_head.global_transform = Transform3D(Basis(new_q), cur_t.origin)

func _try_fire() -> void:
	if is_dead or player == null or bullet_scene == null: return
	var dist = global_position.distance_to(player.global_position)
	if dist > sight_range: return
	# Check line-of-sight
	if not _has_line_of_sight(): return

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_transform = muzzle.global_transform
	if bullet.has_method("launch"):
		# Direction = muzzle's forward
		bullet.launch(-muzzle.global_transform.basis.z)

	# Muzzle flash
	if muzzle_light:
		muzzle_light.light_energy = 6.0
		var tw := create_tween()
		tw.tween_property(muzzle_light, "light_energy", 0.0, 0.12)

func _has_line_of_sight() -> bool:
	if player == null: return false
	var space_state := get_world_3d().direct_space_state
	var from := muzzle.global_position
	var to := player.global_position + Vector3.UP * 0.8
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [self]
	var hit := space_state.intersect_ray(q)
	return hit.is_empty() or hit.collider == player

func take_damage(amount: int) -> void:
	if is_dead: return
	current_health -= amount
	# Flash core scale-pop briefly on hit
	if has_node("TurretHead/CoreMesh"):
		var m: MeshInstance3D = $TurretHead/CoreMesh
		var tw := create_tween()
		m.scale = Vector3(1.15, 1.15, 1.15)
		tw.tween_property(m, "scale", Vector3.ONE, 0.12)
	# Hit sound
	var stream = load("res://audio/hit.wav")
	if stream:
		var p := AudioStreamPlayer.new()
		p.stream = stream
		p.volume_db = -2.0
		get_tree().current_scene.add_child(p)
		p.play()
		p.finished.connect(p.queue_free)
	if current_health <= 0:
		_die()

func _die() -> void:
	is_dead = true
	fire_timer.stop()
	if ammo_pickup_scene and randf() < drop_chance:
		var pickup = ammo_pickup_scene.instantiate()
		get_tree().current_scene.add_child(pickup)
		pickup.global_position = global_position + Vector3(0, 1.5, 0)
	get_tree().call_group("game_manager", "on_enemy_killed", self)
	# Visual flash + fade
	if has_node("TurretHead/CoreMesh"):
		var m = $TurretHead/CoreMesh
		var tw := create_tween()
		tw.tween_property(m, "scale", Vector3.ZERO, 0.4)
	await get_tree().create_timer(0.5).timeout
	queue_free()

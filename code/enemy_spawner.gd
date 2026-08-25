extends Node3D
# EnemySpawner — Doom-style infinite spawner with rate limiting.
# Spawns enemies near its location; only spawns if current alive count < max_alive.

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 4.0     # seconds between spawn attempts
@export var max_alive: int = 3              # cap to avoid overrun
@export var max_total: int = 999            # 999 ≈ infinite
@export var initial_delay: float = 2.0      # wait at level start
@export var spawn_radius: float = 8.0        # randomize spawn pos within this radius (wider = spread across area)
@export var pause_during_low_ammo: bool = false  # if true, slow down when player has < 4 ammo

var alive: Array[Node] = []
var total_spawned: int = 0
var time_to_next: float

func _ready() -> void:
	time_to_next = initial_delay

func _process(delta: float) -> void:
	# Clean up dead refs
	alive = alive.filter(func(n): return is_instance_valid(n))

	if total_spawned >= max_total: return
	if alive.size() >= max_alive:
		time_to_next = spawn_interval  # reset to avoid immediate spawn when one dies
		return

	time_to_next -= delta
	if time_to_next <= 0.0:
		time_to_next = spawn_interval
		_spawn()

func _spawn() -> void:
	if enemy_scene == null: return
	var e = enemy_scene.instantiate()
	get_tree().current_scene.add_child(e)
	var offset := Vector3(
		randf_range(-spawn_radius, spawn_radius),
		0,
		randf_range(-spawn_radius, spawn_radius)
	)
	e.global_position = global_position + offset
	alive.append(e)
	total_spawned += 1

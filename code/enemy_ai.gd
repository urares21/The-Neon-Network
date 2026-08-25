extends CharacterBody3D
# ============================================================
# EnemyAI.gd — Sentinel (singurul tip de inamic)
# FSM: PATROL -> CHASE -> ATTACK -> DEAD
# Fallback: dacă patrol_points e gol, sare direct la CHASE când vede jucătorul.
# ============================================================

enum State { PATROL, CHASE, ATTACK, DEAD }

@export var move_speed: float = 4.0
@export var chase_speed: float = 6.0
@export var attack_range: float = 2.2
@export var attack_damage: int = 12
@export var sight_range: float = 28.0
@export var max_health: int = 60
@export var patrol_points: Array[NodePath] = []
@export var attack_cooldown_sec: float = 1.2
@export var ammo_pickup_scene: PackedScene
@export var drop_chance: float = 0.7

const GRAVITY: float = 18.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var mesh_root: Node3D = $MeshRoot
@onready var attack_timer: Timer = $AttackTimer

var state: int = State.PATROL
var current_health: int
var player: Node3D = null
var current_patrol_index: int = 0
var can_attack: bool = true

func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")
	attack_timer.wait_time = attack_cooldown_sec
	attack_timer.one_shot = true
	if not attack_timer.timeout.is_connected(_on_attack_cooldown):
		attack_timer.timeout.connect(_on_attack_cooldown)
	# Caută jucătorul în scenă
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if patrol_points.size() > 0:
		_go_to_next_patrol_point()

func _on_attack_cooldown() -> void:
	can_attack = true

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# State transitions
	if player and state != State.DEAD:
		var dist: float = global_position.distance_to(player.global_position)
		if dist <= attack_range:
			state = State.ATTACK
		elif dist <= sight_range and _has_line_of_sight():
			state = State.CHASE
		elif state == State.CHASE and dist > sight_range * 1.3:
			state = State.PATROL  # pierdut LOS, înapoi la patrol

	match state:
		State.PATROL:
			_patrol()
		State.CHASE:
			_chase()
		State.ATTACK:
			_attack()

	move_and_slide()

func _patrol() -> void:
	if patrol_points.is_empty():
		# Stă pe loc dacă nu are waypoint-uri
		velocity.x = 0; velocity.z = 0
		return
	if nav_agent.is_navigation_finished():
		_go_to_next_patrol_point()
		return
	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var dir: Vector3 = (next_pos - global_position).normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	_face(next_pos)

func _chase() -> void:
	if player == null:
		state = State.PATROL; return
	nav_agent.target_position = player.global_position
	if nav_agent.is_navigation_finished():
		return
	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var dir: Vector3 = (next_pos - global_position).normalized()
	velocity.x = dir.x * chase_speed
	velocity.z = dir.z * chase_speed
	_face(player.global_position)

func _attack() -> void:
	velocity.x = 0
	velocity.z = 0
	if player:
		_face(player.global_position)
	if can_attack and player and player.has_method("take_damage"):
		player.take_damage(attack_damage)
		can_attack = false
		attack_timer.start()
	if player and global_position.distance_to(player.global_position) > attack_range * 1.4:
		state = State.CHASE

func _go_to_next_patrol_point() -> void:
	if patrol_points.is_empty(): return
	var target_node: Node3D = get_node(patrol_points[current_patrol_index])
	nav_agent.target_position = target_node.global_position
	current_patrol_index = (current_patrol_index + 1) % patrol_points.size()

func _has_line_of_sight() -> bool:
	if player == null: return false
	var space_state := get_world_3d().direct_space_state
	var from := global_position + Vector3.UP * 1.2
	var to := player.global_position + Vector3.UP * 1.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [self]
	var hit := space_state.intersect_ray(q)
	return hit.is_empty() or hit.collider == player

func _face(point: Vector3) -> void:
	var flat := Vector3(point.x, global_position.y, point.z)
	if flat.distance_to(global_position) > 0.05:
		look_at(flat, Vector3.UP)

func take_damage(amount: int) -> void:
	if state == State.DEAD: return
	current_health -= amount
	if current_health <= 0:
		_die()

func _die() -> void:
	state = State.DEAD
	# Spawn ammo drop
	if ammo_pickup_scene and randf() < drop_chance:
		var pickup = ammo_pickup_scene.instantiate()
		get_tree().current_scene.add_child(pickup)
		pickup.global_position = global_position + Vector3(0, 1.0, 0)
	if mesh_root:
		mesh_root.visible = false
	get_tree().call_group("game_manager", "on_enemy_killed", self)
	await get_tree().create_timer(0.3).timeout
	queue_free()

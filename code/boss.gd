extends StaticBody3D
# Boss — giant head with THREE rotating attacks:
#   1. BEAM   — single high-damage laser
#   2. SPRAY  — fan of 7 enemy bullets in a cone toward player
#   3. EXPLOSION — AOE damage that ignores walls (telegraphed by red flash)

@export var max_health: int = 2500
@export var attack_interval: float = 1.8
@export var beam_damage: int = 14
@export var explosion_damage: int = 22
@export var explosion_radius: float = 14.0
@export var spray_damage: int = 6
@export var spray_count: int = 7
@export var spray_spread_deg: float = 30.0
@export var enemy_bullet_scene: PackedScene

@onready var head: Node3D = $Head
@onready var eye_left: OmniLight3D = $Head/EyeLeft
@onready var eye_right: OmniLight3D = $Head/EyeRight
@onready var hp_label: Label3D = $HpLabel
@onready var fire_timer: Timer = $FireTimer
@onready var beam_visual: MeshInstance3D = $BeamVisual
@onready var explosion_visual: MeshInstance3D = $ExplosionVisual

signal boss_health_changed(current: int, max_value: int)
signal boss_killed

enum AttackKind { BEAM, SPRAY, EXPLOSION }

var current_health: int
var player: Node3D = null
var is_dead: bool = false
var next_attack: int = 0

func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")
	add_to_group("boss")
	beam_visual.visible = false
	if explosion_visual: explosion_visual.visible = false
	fire_timer.wait_time = attack_interval
	fire_timer.timeout.connect(_fire_attack)
	fire_timer.start()
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	_update_hp_label()
	emit_signal("boss_health_changed", current_health, max_health)
	for h in get_tree().get_nodes_in_group("hud"):
		if h.has_method("show_boss_bar"):
			h.show_boss_bar(self)

func _physics_process(_delta: float) -> void:
	if is_dead or player == null: return
	var target := player.global_position + Vector3.UP * 1.0
	if target.distance_to(head.global_position) > 0.1:
		var t := head.global_transform
		var d := t.looking_at(target, Vector3.UP)
		head.global_transform = Transform3D(d.basis, t.origin)

func _fire_attack() -> void:
	if is_dead: return
	# Re-find player in case it was loaded after our _ready
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	if player == null: return
	# No sight_range gate — boss is always angry
	match next_attack:
		AttackKind.BEAM:     _fire_beam()
		AttackKind.SPRAY:    _fire_spray()
		AttackKind.EXPLOSION: _fire_explosion()
	next_attack = (next_attack + 1) % 3

func _flash_eyes(color: Color, energy: float = 14.0, dur: float = 0.35) -> void:
	eye_left.light_color = color
	eye_right.light_color = color
	eye_left.light_energy = energy
	eye_right.light_energy = energy
	var tw := create_tween()
	tw.tween_property(eye_left, "light_energy", 4.0, dur)
	tw.parallel().tween_property(eye_right, "light_energy", 4.0, dur)

func _fire_beam() -> void:
	_flash_eyes(Color(1, 0.3, 0.3, 1), 14.0)
	var from := head.global_position
	var to := player.global_position + Vector3.UP * 0.6
	var space_state := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [self]
	var hit := space_state.intersect_ray(q)
	var hit_pos: Vector3 = to
	var hit_player: bool = hit.is_empty() or hit.collider == player
	if not hit.is_empty():
		hit_pos = hit.position
	_show_beam(from, hit_pos)
	if hit_player and player.has_method("take_damage"):
		player.take_damage(beam_damage)

func _fire_spray() -> void:
	_flash_eyes(Color(1, 0.7, 0.1, 1), 12.0)
	if enemy_bullet_scene == null: return
	var dir_to_player: Vector3 = (player.global_position + Vector3.UP * 0.6 - head.global_position).normalized()
	for i in range(spray_count):
		var t: float = float(i) / max(1, spray_count - 1)
		var angle: float = lerp(-spray_spread_deg, spray_spread_deg, t)
		var spread_dir: Vector3 = dir_to_player.rotated(Vector3.UP, deg_to_rad(angle))
		var b = enemy_bullet_scene.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = head.global_position + spread_dir * 1.5
		if b.has_method("launch"):
			b.launch(spread_dir)

func _fire_explosion() -> void:
	_flash_eyes(Color(1, 0.1, 0.6, 1), 18.0, 0.6)
	# Visual: expanding sphere
	if explosion_visual:
		explosion_visual.visible = true
		explosion_visual.scale = Vector3(0.2, 0.2, 0.2)
		var tw := create_tween()
		tw.tween_property(explosion_visual, "scale", Vector3.ONE * (explosion_radius / 5.0), 0.6)
		tw.tween_callback(func(): explosion_visual.visible = false)
	# AOE damage — wall ignoring (psychic shockwave)
	var dist := global_position.distance_to(player.global_position)
	if dist <= explosion_radius and player.has_method("take_damage"):
		var falloff: float = 1.0 - (dist / explosion_radius)
		var dmg: int = int(explosion_damage * max(falloff, 0.3))
		player.take_damage(dmg)

func _show_beam(a: Vector3, b: Vector3) -> void:
	var mid := (a + b) * 0.5
	var len := a.distance_to(b)
	beam_visual.visible = true
	beam_visual.global_position = mid
	beam_visual.look_at(b, Vector3.UP)
	beam_visual.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
	beam_visual.scale = Vector3(0.22, len * 0.5, 0.22)
	var tw := create_tween()
	tw.tween_property(beam_visual, "scale:x", 0.0, 0.3)
	tw.parallel().tween_property(beam_visual, "scale:z", 0.0, 0.3)
	tw.tween_callback(func(): beam_visual.visible = false)

func take_damage(amount: int) -> void:
	if is_dead: return
	current_health -= amount
	emit_signal("boss_health_changed", current_health, max_health)
	_update_hp_label()
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

func _update_hp_label() -> void:
	if hp_label:
		hp_label.text = "MAINFRAME CORE  %d / %d" % [max(current_health, 0), max_health]

func _die() -> void:
	is_dead = true
	fire_timer.stop()
	emit_signal("boss_killed")
	get_tree().call_group("game_manager", "on_enemy_killed", self)
	if eye_left: eye_left.light_energy = 30.0
	if eye_right: eye_right.light_energy = 30.0
	var tw := create_tween()
	tw.tween_property($Head, "scale", Vector3.ZERO, 0.8)
	await get_tree().create_timer(1.0).timeout
	queue_free()

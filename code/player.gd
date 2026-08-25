extends CharacterBody3D
# ============================================================
# Player.gd — Virus FPS controller with ammo + reload.
# ============================================================

@export var move_speed: float = 7.0
@export var sprint_multiplier: float = 1.6
@export var jump_velocity: float = 8.5  # ~1.6m max jump height with g=22
@export var mouse_sensitivity: float = 0.0025
@export var max_health: int = 100
@export var fire_rate: float = 0.18
@export var bullet_scene: PackedScene

# Ammo
@export var ammo_max: int = 12
@export var reload_time: float = 1.5

const GRAVITY: float = 22.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var shoot_ray: RayCast3D = $Head/Camera3D/ShootRay
@onready var muzzle: Marker3D = $Head/Camera3D/MuzzlePoint
@onready var muzzle_flash: OmniLight3D = get_node_or_null("Head/Camera3D/MuzzlePoint/MuzzleFlash")

var current_health: int
var fire_cooldown: float = 0.0
var access_keys_collected: int = 0
var data_packets: int = 0
var ammo_current: int
var is_reloading: bool = false
var reload_timer: float = 0.0

signal health_changed(new_health: int)
signal keys_changed(new_count: int)
signal data_changed(new_count: int)
signal ammo_changed(current: int, max_ammo: int, reloading: bool)
signal player_died

func _ready() -> void:
	current_health = max_health
	ammo_current = ammo_max
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	emit_signal("health_changed", current_health)
	emit_signal("ammo_changed", ammo_current, ammo_max, false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))

func _physics_process(delta: float) -> void:
	# Kill-Z: if player falls below the map, die
	if global_position.y < -15.0 and current_health > 0:
		take_damage(max_health * 2)  # instant kill
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# Save platform velocity while standing on a moving platform.
	var plat_vel: Vector3 = Vector3.ZERO
	if is_on_floor():
		plat_vel = get_platform_velocity()

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		# Inherit the platform's horizontal momentum on jump.
		velocity.x += plat_vel.x
		velocity.z += plat_vel.z

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed: float = move_speed * (sprint_multiplier if Input.is_action_pressed("sprint") else 1.0)

	if is_on_floor():
		# Full ground control
		if direction != Vector3.ZERO:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed * 0.2)
			velocity.z = move_toward(velocity.z, 0, speed * 0.2)
	else:
		# In air: keep momentum, only steer gently with input (no hard reset)
		if direction != Vector3.ZERO:
			var target_x: float = direction.x * speed
			var target_z: float = direction.z * speed
			velocity.x = lerp(velocity.x, target_x, 0.05)
			velocity.z = lerp(velocity.z, target_z, 0.05)
		# If no input, keep current horizontal velocity (full momentum)

	move_and_slide()

	# Reload
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			ammo_current = ammo_max
			is_reloading = false
			emit_signal("ammo_changed", ammo_current, ammo_max, false)
	elif Input.is_action_just_pressed("reload") and ammo_current < ammo_max:
		_start_reload()

	# Shoot
	fire_cooldown = max(fire_cooldown - delta, 0.0)
	if Input.is_action_pressed("shoot") and fire_cooldown <= 0.0 and not is_reloading and ammo_current > 0:
		shoot()
		fire_cooldown = fire_rate

	# Auto-reload if empty (after short delay)
	if ammo_current <= 0 and not is_reloading:
		_start_reload()

func _start_reload() -> void:
	if is_reloading: return
	is_reloading = true
	reload_timer = reload_time
	emit_signal("ammo_changed", ammo_current, ammo_max, true)

func shoot() -> void:
	ammo_current = max(ammo_current - 1, 0)
	emit_signal("ammo_changed", ammo_current, ammo_max, false)

	# Muzzle flash
	if muzzle_flash:
		muzzle_flash.light_energy = 8.0
		var tw := create_tween()
		tw.tween_property(muzzle_flash, "light_energy", 0.0, 0.08)

	# Sound — try the pre-set ShootSound node first; fall back to dynamic load.
	var played_sound: bool = false
	var sp_node = get_node_or_null("ShootSound")
	if sp_node and sp_node is AudioStreamPlayer:
		if sp_node.stream == null:
			sp_node.stream = load("res://audio/shoot.wav")
		if sp_node.stream:
			sp_node.play()
			played_sound = true
	if not played_sound:
		var shoot_stream = load("res://audio/shoot.wav")
		if shoot_stream:
			var sp := AudioStreamPlayer.new()
			sp.stream = shoot_stream
			sp.volume_db = 0.0
			get_tree().current_scene.add_child(sp)
			sp.play()
			sp.finished.connect(sp.queue_free)

	if bullet_scene != null:
		var bullet := bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_transform = muzzle.global_transform
		if bullet.has_method("launch"):
			bullet.launch(-camera.global_transform.basis.z)
		return

	# Fallback hitscan
	if shoot_ray.is_colliding():
		var target = shoot_ray.get_collider()
		if target and target.has_method("take_damage"):
			target.take_damage(25)

func take_damage(amount: int) -> void:
	current_health = max(current_health - amount, 0)
	emit_signal("health_changed", current_health)
	# Play hit sound
	var stream = load("res://audio/hit.wav")
	if stream:
		var p := AudioStreamPlayer.new()
		p.stream = stream
		p.volume_db = -3.0
		get_tree().current_scene.add_child(p)
		p.play()
		p.finished.connect(p.queue_free)
	if current_health <= 0:
		emit_signal("player_died")
		get_tree().call_group("game_manager", "on_player_died")

func collect_key() -> void:
	access_keys_collected += 1
	emit_signal("keys_changed", access_keys_collected)

func collect_data() -> void:
	data_packets += 1
	emit_signal("data_changed", data_packets)

func collect_ammo(amount: int) -> void:
	ammo_current = min(ammo_current + amount, ammo_max)
	emit_signal("ammo_changed", ammo_current, ammo_max, is_reloading)

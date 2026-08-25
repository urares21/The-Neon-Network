extends CanvasLayer
# ============================================================
# HUD.gd — Heads-Up Display + Pause Menu
# HUD-ul are process_mode = ALWAYS (3) ca să poată asculta ESC chiar și
# când get_tree().paused = true. Timer-ul nu avansează când e pauză.
# ============================================================

@onready var health_bar: ProgressBar = $BottomPanel/HealthBar
@onready var health_label: Label = $BottomPanel/HealthLabel
@onready var keys_label: Label = $BottomPanel/KeysLabel
@onready var data_label: Label = $BottomPanel/DataLabel
@onready var ammo_label: Label = $AmmoLabel
@onready var reload_hint: Label = $ReloadHint
@onready var timer_label: Label = $TimerPanel/TimerLabel
@onready var message_label: Label = $MessageLabel
@onready var objective_label: Label = $ObjectiveLabel
@onready var pause_overlay: Control = $PauseOverlay
@onready var boss_panel: Panel = $BossPanel
@onready var boss_bar: ProgressBar = $BossPanel/BossBar
@onready var boss_label: Label = $BossPanel/BossLabel

@export var time_limit_seconds: float = 180.0
@export var keys_required: int = 3
@export var objective_text: String = ""

var time_left: float
var is_paused: bool = false

func _ready() -> void:
	add_to_group("hud")
	time_left = time_limit_seconds
	message_label.text = ""
	pause_overlay.visible = false
	boss_panel.visible = false
	if objective_label and objective_text != "":
		objective_label.text = objective_text
	keys_label.text = "KEYS: 0 / %d" % keys_required

	# Conectează butoanele pause
	$PauseOverlay/PausePanel/VBoxContainer/ResumeButton.pressed.connect(_on_resume)
	$PauseOverlay/PausePanel/VBoxContainer/RestartButton.pressed.connect(_on_restart)
	$PauseOverlay/PausePanel/VBoxContainer/LevelSelectButton.pressed.connect(_on_level_select)
	$PauseOverlay/PausePanel/VBoxContainer/QuitButton.pressed.connect(_on_quit)

	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		player.keys_changed.connect(_on_keys_changed)
		player.data_changed.connect(_on_data_changed)
		if player.has_signal("ammo_changed"):
			player.ammo_changed.connect(_on_ammo_changed)
			_on_ammo_changed(player.ammo_current, player.ammo_max, false)
		_on_health_changed(player.current_health)

func _input(event: InputEvent) -> void:
	# Use _input (not _unhandled_input) so we catch ESC before any UI consumption.
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if is_paused or get_tree().paused:
		return
	time_left = max(time_left - delta, 0.0)
	var m: int = int(time_left) / 60
	var s: int = int(time_left) % 60
	timer_label.text = "%02d:%02d" % [m, s]
	if time_left < 30.0:
		var pulse: float = 0.6 + 0.4 * abs(sin(time_left * 4.0))
		timer_label.modulate = Color(1.0, 0.2 * pulse, 0.2 * pulse, 1.0)
	if time_left <= 0.0:
		get_tree().call_group("game_manager", "on_time_expired")
		set_process(false)

# ---------- Pause ----------
func toggle_pause() -> void:
	is_paused = not is_paused
	pause_overlay.visible = is_paused
	get_tree().paused = is_paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_paused else Input.MOUSE_MODE_CAPTURED

func _on_resume() -> void:
	toggle_pause()

func _on_restart() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().reload_current_scene()

func _on_level_select() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_quit() -> void:
	get_tree().paused = false
	get_tree().quit()

# ---------- Player signals ----------
func _on_health_changed(value: int) -> void:
	health_bar.value = value
	health_label.text = "%d / 100" % value
	if value < 30:
		health_bar.modulate = Color(1.0, 0.2, 0.2)
	elif value < 60:
		health_bar.modulate = Color(1.0, 0.7, 0.0)
	else:
		health_bar.modulate = Color(0.2, 1.0, 0.6)

func _on_keys_changed(value: int) -> void:
	keys_label.text = "KEYS: %d / %d" % [value, keys_required]
	flash_message("KEY ACQUIRED")

func _on_data_changed(value: int) -> void:
	data_label.text = "DATA: %d" % value
	flash_message("DATA EXTRACTED", 1.0)

func _on_ammo_changed(current: int, max_ammo: int, reloading: bool) -> void:
	if reloading:
		ammo_label.text = "RELOADING…"
		ammo_label.modulate = Color(1, 0.5, 0.2, 1)
	else:
		ammo_label.text = "AMMO  %d / %d" % [current, max_ammo]
		if current <= 3:
			ammo_label.modulate = Color(1, 0.2, 0.2, 1)
		elif current <= max_ammo / 3:
			ammo_label.modulate = Color(1, 0.7, 0.2, 1)
		else:
			ammo_label.modulate = Color(0, 1, 0.85, 1)

func show_boss_bar(boss: Node) -> void:
	boss_panel.visible = true
	if boss.has_signal("boss_health_changed"):
		boss.boss_health_changed.connect(_on_boss_health_changed)
	if boss.has_signal("boss_killed"):
		boss.boss_killed.connect(_on_boss_killed)
	if "max_health" in boss:
		boss_bar.max_value = boss.max_health
		boss_bar.value = boss.max_health
	if "current_health" in boss:
		boss_bar.value = boss.current_health

func _on_boss_health_changed(current: int, max_value: int) -> void:
	boss_bar.max_value = max_value
	boss_bar.value = current
	# Tint red as HP drops
	var f: float = clamp(float(current) / float(max_value), 0.0, 1.0)
	boss_bar.modulate = Color(1.0, 0.2 + 0.6 * f, 0.2 + 0.6 * f, 1.0)

func _on_boss_killed() -> void:
	boss_panel.visible = false

func flash_message(text: String, duration: float = 1.4) -> void:
	message_label.text = text
	message_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(message_label, "modulate:a", 0.0, duration)

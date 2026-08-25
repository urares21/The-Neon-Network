extends Node
# ============================================================
# GameManager.gd — Autoload singleton.
# Setează input map la pornire (nu trebuie configurat manual în Project Settings).
# Coordonează tranzițiile între scene și starea de win/lose.
# ============================================================

signal level_changed(level_name: String)
signal game_over(reason: String)
signal victory

var current_level_index: int = 0
var total_enemies_killed: int = 0
var total_data_stolen: int = 0
var run_start_time_ms: int = 0
var last_game_over_reason: String = ""
var last_level_path: String = "res://scenes/Level01.tscn"

func _ready() -> void:
	add_to_group("game_manager")
	_setup_input_map()
	run_start_time_ms = Time.get_ticks_msec()
	_start_music()

func _start_music() -> void:
	var music = AudioStreamPlayer.new()
	music.name = "Music"
	var stream = load("res://audio/ambient.wav")
	if stream:
		# Enable looping
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_end = stream.data.size() / 2  # samples (mono 16-bit)
		music.stream = stream
		music.volume_db = -10.0
		music.autoplay = true
		add_child(music)

func _setup_input_map() -> void:
	# Tastatură (folosește physical_keycode → funcționează indiferent de layout)
	var keys := {
		"move_forward": KEY_W,
		"move_back":    KEY_S,
		"move_left":    KEY_A,
		"move_right":   KEY_D,
		"jump":         KEY_SPACE,
		"sprint":       KEY_SHIFT,
		"interact":     KEY_E,
	}
	for action_name in keys.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			var ev := InputEventKey.new()
			ev.physical_keycode = keys[action_name]
			InputMap.action_add_event(action_name, ev)

	# Mouse
	if not InputMap.has_action("shoot"):
		InputMap.add_action("shoot")
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("shoot", ev)

	# Reload (R)
	if not InputMap.has_action("reload"):
		InputMap.add_action("reload")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_R
		InputMap.action_add_event("reload", ev)

	# Force-register ui_cancel (Godot default but we want to be sure)
	if not InputMap.has_action("ui_cancel"):
		InputMap.add_action("ui_cancel")
	var has_esc := false
	for e in InputMap.action_get_events("ui_cancel"):
		if e is InputEventKey and e.physical_keycode == KEY_ESCAPE:
			has_esc = true
			break
	if not has_esc:
		var esc := InputEventKey.new()
		esc.physical_keycode = KEY_ESCAPE
		InputMap.action_add_event("ui_cancel", esc)

func on_level_complete(next_scene_path: String) -> void:
	current_level_index += 1
	emit_signal("level_changed", next_scene_path)
	if next_scene_path == "" or next_scene_path == "VICTORY":
		_show_victory()
	else:
		# Permite mouse-ul liber în meniuri intermediare (deși aici încărcăm direct)
		get_tree().change_scene_to_file(next_scene_path)

func on_player_died() -> void:
	last_game_over_reason = "PLAYER DESTROYED BY FIREWALL"
	# Remember which level the player was on, so Retry restarts THIS level
	var sc = get_tree().current_scene
	if sc and sc.scene_file_path != "":
		last_level_path = sc.scene_file_path
	emit_signal("game_over", last_game_over_reason)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func on_time_expired() -> void:
	last_game_over_reason = "TRACE COMPLETE — VIRUS QUARANTINED"
	var sc = get_tree().current_scene
	if sc and sc.scene_file_path != "":
		last_level_path = sc.scene_file_path
	emit_signal("game_over", last_game_over_reason)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func on_enemy_killed(_enemy) -> void:
	total_enemies_killed += 1

func _show_victory() -> void:
	emit_signal("victory")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/Victory.tscn")

func get_run_time_seconds() -> float:
	return (Time.get_ticks_msec() - run_start_time_ms) / 1000.0

func reset_run() -> void:
	current_level_index = 0
	total_enemies_killed = 0
	total_data_stolen = 0
	run_start_time_ms = Time.get_ticks_msec()

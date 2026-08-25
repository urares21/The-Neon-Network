extends Control
# ============================================================
# Menu.gd — Main menu / GameOver / Victory.
# Finds buttons by name recursively, so it works regardless of nesting
# (Main.tscn uses VBoxRoot/Row1/Level1Button, GameOver/Victory use
# CenterContainer/VBoxContainer/...).
# ============================================================

@export var start_scene: String = "res://scenes/Intro.tscn"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false

	_bind("PlayButton",   _on_play)
	_bind("Level1Button", _on_level1)
	_bind("Level2Button", _on_level2)
	_bind("Level3Button", _on_level3)
	_bind("Level4Button", _on_level4)
	_bind("Level5Button", _on_level5)
	_bind("Level6Button", _on_level6)
	_bind("Level7Button", _on_level7)
	_bind("Level8Button", _on_level8)
	_bind("QuitButton",   _on_quit)
	_bind("RetryButton",  _on_retry)
	_bind("MenuButton",   _on_menu)

	# Stats label (GameOver / Victory)
	var stats = _find("StatsLabel")
	if stats:
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			var t: float = gm.get_run_time_seconds()
			stats.text = "Time: %02d:%02d   ·   Kills: %d   ·   Data: %d" %\
				[int(t)/60, int(t)%60, gm.total_enemies_killed, gm.total_data_stolen]

	var reason = _find("ReasonLabel")
	if reason:
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.last_game_over_reason != "":
			reason.text = gm.last_game_over_reason

func _find(node_name: String) -> Node:
	return _find_recursive(self, node_name)

func _find_recursive(parent: Node, target: String) -> Node:
	for child in parent.get_children():
		if child.name == target:
			return child
		var deeper = _find_recursive(child, target)
		if deeper:
			return deeper
	return null

func _bind(button_name: String, handler: Callable) -> void:
	var b = _find(button_name)
	if b and b is BaseButton:
		if not b.pressed.is_connected(handler):
			b.pressed.connect(handler)

func _on_play()   -> void: _start(start_scene)
func _on_level1() -> void: _start("res://scenes/Level01.tscn")
func _on_level2() -> void: _start("res://scenes/Level02.tscn")
func _on_level3() -> void: _start("res://scenes/Level03.tscn")
func _on_level4() -> void: _start("res://scenes/Level04.tscn")
func _on_level5() -> void: _start("res://scenes/Level05.tscn")
func _on_level6() -> void: _start("res://scenes/Level06.tscn")
func _on_level7() -> void: _start("res://scenes/Level07.tscn")
func _on_level8() -> void: _start("res://scenes/Level08.tscn")
func _on_retry() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var path = "res://scenes/Level01.tscn"
	if gm and gm.last_level_path != "":
		path = gm.last_level_path
	_start(path)

func _on_quit() -> void:
	get_tree().quit()

func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _start(scene_path: String) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm: gm.reset_run()
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)

extends Control
# Intro screen — typewriter story text. Input gated until 0.3s after scene start
# so a held click from the menu button doesn't immediately skip.

@export var next_scene: String = "res://scenes/Level01.tscn"
@export var line_delay: float = 0.5
@export var char_delay: float = 0.03

const LINES := [
	"> CONNECTION ESTABLISHED.",
	"> UPLOADING PAYLOAD...",
	"",
	"You are an anomaly.",
	"A self-replicating virus, uploaded into the Neon Network -",
	"the defense grid of a corporate supercomputer.",
	"",
	"Three security servers stand between you and the Mainframe Core.",
	"Destroy the firewalls. Steal the corrupted data packet.",
	"Escape before they trace you.",
	"",
	"> TIME LIMIT: 3 MINUTES PER SERVER.",
	"> TRACE STATUS: ACTIVE.",
	"",
	"Good luck, anomaly.",
]

@onready var label: Label = $StoryLabel

var line_index: int = 0
var char_index: int = 0
var char_accum: float = 0.0
var line_accum: float = 0.0
var finished: bool = false
var input_lock_time: float = 0.3   # ignore inputs for the first 0.3s

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if label:
		label.text = ""

func _process(delta: float) -> void:
	if finished: return
	if input_lock_time > 0.0:
		input_lock_time -= delta

	if line_index >= LINES.size():
		line_accum += delta
		if line_accum > 1.5:
			_go_next()
		return

	var line: String = LINES[line_index]
	if char_index < line.length():
		char_accum += delta
		if char_accum >= char_delay:
			char_accum = 0.0
			char_index += 1
			label.text = _build_visible_text()
	else:
		line_accum += delta
		if line_accum >= line_delay:
			line_accum = 0.0
			char_index = 0
			line_index += 1
			label.text = _build_visible_text()

func _build_visible_text() -> String:
	var result := ""
	for i in line_index:
		result += LINES[i] + "\n"
	if line_index < LINES.size():
		result += LINES[line_index].substr(0, char_index)
	return result

func _input(event: InputEvent) -> void:
	if input_lock_time > 0.0: return
	# Only react to *fresh* press transitions, not held-down state.
	if (event is InputEventKey and event.pressed and not event.echo) \
	or (event is InputEventMouseButton and event.pressed):
		_go_next()

func _go_next() -> void:
	if finished: return
	finished = true
	get_tree().change_scene_to_file(next_scene)

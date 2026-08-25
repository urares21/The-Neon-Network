extends Area3D
# JumpPad — launches the player upward when stepped on.

@export var launch_velocity: float = 16.0   # ~3.6m peak vs default 8.5

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# Reset gravity so launch is clean
		if "velocity" in body:
			body.velocity.y = launch_velocity
		# Visual punch
		var mesh = get_node_or_null("Mesh")
		if mesh:
			var tw := create_tween()
			mesh.scale = Vector3(1.3, 0.5, 1.3)
			tw.tween_property(mesh, "scale", Vector3.ONE, 0.25)

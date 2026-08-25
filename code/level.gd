extends Node3D
# ============================================================
# Level.gd — helper atașat pe Node3D root al fiecărui nivel
# Bake-uiește navigation mesh la pornire (ca să nu trebuiască manual din editor)
# și instanțiază HUD-ul cu parametrii corecți.
# ============================================================

@export var level_name: String = "Boot Sector"
@export var time_limit_seconds: float = 180.0
@export var keys_required: int = 3
@export var objective: String = "Strânge cheile · activează portalul"
@export var nav_region_path: NodePath = NodePath("NavigationRegion3D")
@export var hud_scene: PackedScene

func _ready() -> void:
	# Configurează HUD-ul, dacă scena lui e atașată
	if hud_scene:
		var hud = hud_scene.instantiate()
		if hud is CanvasLayer:
			hud.time_limit_seconds = time_limit_seconds
			hud.keys_required = keys_required
			hud.objective_text = "%s — %s" % [level_name.to_upper(), objective]
		add_child(hud)
	# Bake navigation mesh dacă există NavigationRegion3D
	if has_node(nav_region_path):
		var region: NavigationRegion3D = get_node(nav_region_path)
		if region.navigation_mesh:
			# Așteaptă un frame ca toți copii să fie ready, apoi bake
			await get_tree().process_frame
			region.bake_navigation_mesh()

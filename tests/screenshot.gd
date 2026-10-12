# Lance le jeu et enregistre une capture d'écran.
# Lancer : Godot --path . --script res://tests/screenshot.gd -- <fichier.png> [secondes]
# Variables : SHOT_ZOOM (taille de la caméra, plus petit = plus près), SHOT_FOCUS ("x,z" du point visé),
# SHOT_UNLOAD (lance le déchargement dès le départ).
extends SceneTree

var _out := "user://shot.png"
var _wait := 2.0
var _elapsed := 0.0
var _configured := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	if args.size() > 1:
		_wait = float(args[1])
	change_scene_to_file("res://scenes/main.tscn")


func _process(delta: float) -> bool:
	_elapsed += delta
	if not _configured and current_scene != null:
		_configured = true
		var rig = current_scene.get_node_or_null("CameraRig")
		if rig != null:
			if OS.has_environment("SHOT_ZOOM"):
				rig.target_size = float(OS.get_environment("SHOT_ZOOM"))
				rig.camera.size = rig.target_size
			if OS.has_environment("SHOT_FOCUS"):
				var xz := OS.get_environment("SHOT_FOCUS").split(",")
				rig.position = Vector3(float(xz[0]), rig.ground_y, float(xz[1]))
		if OS.has_environment("SHOT_UNLOAD"):
			current_scene.unloading.start()
	if _elapsed < _wait:
		return false
	var image := root.get_texture().get_image()
	var err := image.save_png(_out)
	print("capture : ", _out, " (", error_string(err), ")")
	return true

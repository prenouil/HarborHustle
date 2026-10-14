# Lance le jeu et enregistre une capture d'écran.
# Lancer : Godot --path . --script res://tests/screenshot.gd -- <fichier.png> [secondes de jeu]
# Variables :
#   SHOT_ZOOM   taille de la caméra (plus petit = plus près)
#   SHOT_FOCUS  "x,z" du point visé
#   SHOT_SETUP  pose un hangar et la grue, achète 2 camions et 2 dockers
#   SHOT_UNLOAD lance le déchargement dès que le bateau est à quai
#   SHOT_SPEED  accélère le temps (Engine.time_scale)
#   SHOT_PLACE  « hangar » ou « crane » : montre le fantôme de placement en « x,z » (SHOT_PLACE_AT)
#   SHOT_BUILD  « hangar » ou « crane » : lance la construction en « x,z » (SHOT_PLACE_AT)
extends SceneTree

var _out := "user://shot.png"
var _wait := 2.0
var _elapsed := 0.0
var _configured := false
var _unload_started := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	if args.size() > 1:
		_wait = float(args[1])
	if OS.has_environment("SHOT_SPEED"):
		Engine.time_scale = float(OS.get_environment("SHOT_SPEED"))
	change_scene_to_file("res://scenes/main.tscn")


func _process(delta: float) -> bool:
	_elapsed += delta
	var main := current_scene
	if main == null:
		return false
	if not _configured:
		_configured = true
		_configure(main)
	if OS.has_environment("SHOT_UNLOAD") and not _unload_started and main.logistics.ship_ready():
		_unload_started = true
		main.logistics.start_unloading()
	if OS.has_environment("SHOT_PLACE"):
		var xz := OS.get_environment("SHOT_PLACE_AT").split(",")
		main.update_placement(Vector3(float(xz[0]), 1.5, float(xz[1])))
	if _elapsed < _wait:
		return false
	var image := root.get_texture().get_image()
	var err := image.save_png(_out)
	print("capture : ", _out, " (", error_string(err), ")")
	Engine.time_scale = 1.0
	return true


func _configure(main: Node) -> void:
	var rig = main.get_node_or_null("CameraRig")
	if OS.has_environment("SHOT_ZOOM"):
		rig.target_size = float(OS.get_environment("SHOT_ZOOM"))
		rig.camera.size = rig.target_size
	if OS.has_environment("SHOT_FOCUS"):
		var xz := OS.get_environment("SHOT_FOCUS").split(",")
		rig.position = Vector3(float(xz[0]), rig.ground_y, float(xz[1]))
	if OS.has_environment("SHOT_SETUP"):
		main.build_now("hangar", Vector3(0, 1.5, -26))
		main.build_now("crane", Vector3(0, 1.5, 0))
		for i in 2:
			main.buy_truck()
			main.buy_docker()
	if OS.has_environment("SHOT_PLACE"):
		main.start_placement(OS.get_environment("SHOT_PLACE"))
	if OS.has_environment("SHOT_BUILD"):
		var xz := OS.get_environment("SHOT_PLACE_AT").split(",")
		main.start_placement(OS.get_environment("SHOT_BUILD"))
		main.update_placement(Vector3(float(xz[0]), 1.5, float(xz[1])))
		main.confirm_placement()

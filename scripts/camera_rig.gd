# Caméra isométrique orthographique : zoom à la molette (vers le curseur),
# déplacement au clic droit / molette enfoncée ou au clavier (ZQSD / flèches).
extends Node3D

const MIN_SIZE := 8.0
const MAX_SIZE := 110.0
const ZOOM_STEP := 1.15
const PITCH := -35.264  # angle de l'isométrie vraie
const DISTANCE := 200.0

# Zone (x, z) dans laquelle le point visé peut se déplacer.
var bounds := Rect2(-70, -55, 140, 90)
# Hauteur du sol de référence (le dessus du quai).
var ground_y := 1.5
var target_size := 42.0
var camera: Camera3D

var _drag := false
var _zoom_anchor := Vector2.ZERO


func _ready() -> void:
	rotation_degrees.y = 45.0
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = target_size
	camera.near = 1.0
	camera.far = 600.0
	var pitch := deg_to_rad(PITCH)
	camera.rotation.x = pitch
	camera.position = Vector3(0, -sin(pitch), cos(pitch)) * DISTANCE
	add_child(camera)
	camera.make_current()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_zoom(1.0 / ZOOM_STEP, event.position)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_zoom(ZOOM_STEP, event.position)
			MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
				_drag = event.pressed
	elif event is InputEventMouseMotion and _drag:
		var mouse: Vector2 = event.position
		position += ground_at(mouse - event.relative) - ground_at(mouse)
		_clamp()


func _process(delta: float) -> void:
	# Zoom amorti, en gardant fixe le point du sol sous le curseur.
	if not is_equal_approx(camera.size, target_size):
		var before := ground_at(_zoom_anchor)
		camera.size = lerpf(camera.size, target_size, 1.0 - exp(-14.0 * delta))
		if absf(camera.size - target_size) < 0.01:
			camera.size = target_size
		position += before - ground_at(_zoom_anchor)
		_clamp()

	# Déplacement au clavier (touches physiques : ZQSD sur AZERTY, WASD sur QWERTY).
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1
	if dir != Vector2.ZERO:
		var move := (basis.x * dir.x + basis.z * dir.y) * camera.size * 0.9 * delta
		position += Vector3(move.x, 0, move.z)
		_clamp()


# Point du sol de référence sous une position de l'écran.
func ground_at(screen: Vector2) -> Vector3:
	var hit = Plane(Vector3.UP, ground_y).intersects_ray(camera.project_ray_origin(screen), camera.project_ray_normal(screen))
	return hit if hit != null else position


func _zoom(factor: float, anchor: Vector2) -> void:
	target_size = clampf(target_size * factor, MIN_SIZE, MAX_SIZE)
	_zoom_anchor = anchor


func _clamp() -> void:
	position.x = clampf(position.x, bounds.position.x, bounds.end.x)
	position.z = clampf(position.z, bounds.position.y, bounds.end.y)
	position.y = ground_y

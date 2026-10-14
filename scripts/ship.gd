# Porte-containers amarré : coque, château arrière et piles de containers.
# Repère local : la longueur suit x (proue vers +x), la largeur suit z, la ligne de flottaison est en y = 0.
extends Node3D

const Blocks = preload("res://scripts/blocks.gd")

const LENGTH := 62.0
const BEAM := 12.0
const DECK_Y := 3.2
const CONTAINER_SIZE := Vector3(6.0, 2.6, 2.4)
const CONTAINER_COLORS := [
	Color("#f08a24"), Color("#d6402f"), Color("#2bb3a8"),
	Color("#f2c230"), Color("#2f6fd6"), Color("#e8e4da"),
]

# Containers prêts à être déchargés, du haut des piles vers le bas.
var containers: Array[Node3D] = []
# Graine du chargement (couleurs et hauteur des piles), à choisir avant l'ajout à la scène.
var rng_seed := 7
# Vrai quand le bateau est amarré au quai.
var moored := false

var _base_y := 0.0
var _time := 0.0


func _ready() -> void:
	_base_y = position.y
	_build_hull()
	_build_castle()
	_build_containers()


func _process(delta: float) -> void:
	# Léger roulis et pilonnement.
	_time += delta
	position.y = _base_y + sin(_time * 0.6) * 0.08
	rotation.x = sin(_time * 0.45) * 0.006


# Navigue le long du quai jusqu'à x (proue vers +x).
func sail_to(x: float, duration: float, easing: Tween.EaseType) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(easing)
	tween.tween_property(self, "position:x", x, duration)
	await tween.finished


# Point d'amarrage sur le pont, en coordonnées locales (avant > 0, arrière < 0).
func cleat(along: float, side: float) -> Vector3:
	return Vector3(along, DECK_Y + 0.3, side * (BEAM * 0.5 - 0.6))


func _build_hull() -> void:
	var h := BEAM * 0.5
	var stern := -LENGTH * 0.5
	var outline := PackedVector2Array([
		Vector2(stern - 1.0, -h + 0.6), Vector2(stern + 1.0, -h), Vector2(LENGTH * 0.5 - 9.0, -h),
		Vector2(LENGTH * 0.5, 0.0),
		Vector2(LENGTH * 0.5 - 9.0, h), Vector2(stern + 1.0, h), Vector2(stern - 1.0, h - 0.6),
	])
	Blocks.add(self, Blocks.prism(outline, -2.5, 0.6), Vector3.ZERO, Color("#c8392f"))
	Blocks.add(self, Blocks.prism(outline, 0.6, DECK_Y), Vector3.ZERO, Color("#24365e"))
	# Liseré blanc et pont.
	Blocks.add(self, Blocks.prism(outline, DECK_Y, DECK_Y + 0.15), Vector3.ZERO, Color("#e8eef7"))
	var inner := PackedVector2Array()
	for p in outline:
		inner.append(p * Vector2(0.97, 0.88))
	Blocks.add(self, Blocks.prism(inner, DECK_Y + 0.15, DECK_Y + 0.2), Vector3.ZERO, Color("#51607e"))
	# Mât de proue.
	Blocks.box(self, Vector3(0.3, 5.0, 0.3), Vector3(LENGTH * 0.5 - 6.0, DECK_Y + 2.5, 0), Color("#e8eef7"))
	Blocks.box(self, Vector3(0.5, 0.5, 0.5), Vector3(LENGTH * 0.5 - 6.0, DECK_Y + 5.2, 0), Color("#ffd27a"), 2.0)


func _build_castle() -> void:
	var x := -LENGTH * 0.5 + 4.5
	var white := Color("#e8eef7")
	var glass := Color("#1b2a4a")
	# Étages.
	Blocks.box(self, Vector3(7, 3, 10), Vector3(x, DECK_Y + 1.5, 0), white)
	Blocks.box(self, Vector3(6.5, 3, 9), Vector3(x - 0.25, DECK_Y + 4.5, 0), white)
	Blocks.box(self, Vector3(6, 2.4, 13), Vector3(x - 0.5, DECK_Y + 7.2, 0), white)
	# Hublots et vitres de la passerelle.
	Blocks.box(self, Vector3(7.06, 0.7, 8.0), Vector3(x, DECK_Y + 2.0, 0), glass)
	Blocks.box(self, Vector3(6.56, 0.7, 7.0), Vector3(x - 0.25, DECK_Y + 5.0, 0), glass)
	Blocks.box(self, Vector3(6.06, 0.9, 12.4), Vector3(x - 0.5, DECK_Y + 7.4, 0), Color("#6fd3ff"), 0.6)
	Blocks.box(self, Vector3(6.4, 0.25, 13.4), Vector3(x - 0.5, DECK_Y + 8.5, 0), Color("#24365e"))
	# Cheminée.
	Blocks.box(self, Vector3(2.4, 3.4, 3), Vector3(x - 2.0, DECK_Y + 10.2, 0), Color("#f08a24"))
	Blocks.box(self, Vector3(2.5, 0.6, 3.1), Vector3(x - 2.0, DECK_Y + 11.7, 0), Color("#1a1d26"))
	# Antennes.
	Blocks.box(self, Vector3(0.15, 2.5, 0.15), Vector3(x + 1.5, DECK_Y + 9.9, 2.0), white)
	Blocks.box(self, Vector3(0.15, 0.15, 2.0), Vector3(x + 1.5, DECK_Y + 10.8, 2.0), white)


func _build_containers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var bays := 6
	var rows := 4
	var first_x := -LENGTH * 0.5 + 11.5
	var stacks := []
	for bay in bays:
		for row in rows:
			var x := first_x + bay * (CONTAINER_SIZE.x + 0.5) + CONTAINER_SIZE.x * 0.5
			var z := (row - (rows - 1) * 0.5) * (CONTAINER_SIZE.z + 0.1)
			var height := rng.randi_range(1, 3)
			var stack := []
			for tier in height:
				var color: Color = CONTAINER_COLORS[rng.randi() % CONTAINER_COLORS.size()]
				var y := DECK_Y + 0.2 + tier * CONTAINER_SIZE.y + CONTAINER_SIZE.y * 0.5
				stack.append(_container(Vector3(x, y, z), color))
			stacks.append(stack)
	# Les containers du dessus d'abord : c'est l'ordre dans lequel on peut les décharger.
	for tier in range(2, -1, -1):
		for stack in stacks:
			if tier < stack.size():
				containers.append(stack[tier])


func _container(pos: Vector3, color: Color) -> Node3D:
	var c := Node3D.new()
	c.position = pos
	add_child(c)
	Blocks.box(c, CONTAINER_SIZE - Vector3(0.1, 0.0, 0.0), Vector3.ZERO, color)
	# Cadres des portes, plus sombres.
	var frame := color.darkened(0.35)
	var end := Vector3(0.12, CONTAINER_SIZE.y + 0.02, CONTAINER_SIZE.z + 0.02)
	Blocks.box(c, end, Vector3(CONTAINER_SIZE.x * 0.5 - 0.06, 0, 0), frame)
	Blocks.box(c, end, Vector3(-CONTAINER_SIZE.x * 0.5 + 0.06, 0, 0), frame)
	# Nervures sur les flancs.
	for i in range(1, 5):
		var rx := -CONTAINER_SIZE.x * 0.5 + i * CONTAINER_SIZE.x / 5.0
		Blocks.box(c, Vector3(0.08, CONTAINER_SIZE.y - 0.3, CONTAINER_SIZE.z + 0.04), Vector3(rx, 0, 0), color.darkened(0.15))
	return c

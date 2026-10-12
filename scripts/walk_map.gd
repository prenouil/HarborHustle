# Zones du quai où le héros peut marcher, et calcul de chemins qui contournent les obstacles.
# Les positions sont dans le plan du sol : Vector2(x, z).
extends RefCounted

# Distance minimale que le héros garde avec les obstacles.
const MARGIN := 0.6

var area: Rect2
var _obstacles: Array[Rect2] = []
var _grid := AStarGrid2D.new()


func _init(walk_area: Rect2, obstacles: Array[Rect2]) -> void:
	area = walk_area
	for rect in obstacles:
		_obstacles.append(rect.grow(MARGIN))
	_grid.region = Rect2i(floori(area.position.x), floori(area.position.y), ceili(area.size.x), ceili(area.size.y))
	_grid.cell_size = Vector2.ONE
	_grid.offset = Vector2(0.5, 0.5)
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.update()
	for x in range(_grid.region.position.x, _grid.region.end.x):
		for y in range(_grid.region.position.y, _grid.region.end.y):
			if not is_walkable(Vector2(x + 0.5, y + 0.5)):
				_grid.set_point_solid(Vector2i(x, y))


func is_walkable(p: Vector2) -> bool:
	if not area.has_point(p):
		return false
	for rect in _obstacles:
		if rect.has_point(p):
			return false
	return true


# Le point praticable le plus proche (le point lui-même s'il l'est déjà).
func nearest_walkable(p: Vector2) -> Vector2:
	if is_walkable(p):
		return p
	var cell := _free_cell(p)
	return Vector2(cell.x + 0.5, cell.y + 0.5)


# Chemin de `from` jusqu'au point praticable le plus proche de `to`, lissé en lignes droites.
# Le premier point est `from`. Vide si aucun chemin n'existe.
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var goal := nearest_walkable(to)
	var raw := _grid.get_point_path(_free_cell(from), _free_cell(goal))
	if raw.is_empty():
		return PackedVector2Array()
	var points := PackedVector2Array([from])
	if raw.size() > 2:
		points.append_array(raw.slice(1, raw.size() - 1))
	points.append(goal)
	return _smooth(points)


# La case libre (non bloquée) la plus proche du point.
func _free_cell(p: Vector2) -> Vector2i:
	var cell := Vector2i(floori(p.x), floori(p.y))
	if _grid.is_in_boundsv(cell) and not _grid.is_point_solid(cell):
		return cell
	var best := cell
	var best_distance := INF
	for x in range(_grid.region.position.x, _grid.region.end.x):
		for y in range(_grid.region.position.y, _grid.region.end.y):
			if _grid.is_point_solid(Vector2i(x, y)):
				continue
			var d := Vector2(x + 0.5, y + 0.5).distance_squared_to(p)
			if d < best_distance:
				best_distance = d
				best = Vector2i(x, y)
	return best


# Saute les points intermédiaires tant que la ligne droite reste praticable.
func _smooth(points: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array([points[0]])
	var i := 0
	while i < points.size() - 1:
		var j := points.size() - 1
		while j > i + 1 and not _is_clear(points[i], points[j]):
			j -= 1
		out.append(points[j])
		i = j
	return out


func _is_clear(a: Vector2, b: Vector2) -> bool:
	var steps := ceili(a.distance_to(b) / 0.25)
	for s in range(1, steps):
		if not is_walkable(a.lerp(b, float(s) / steps)):
			return false
	return true

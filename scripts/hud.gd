# Interface : argent et état du port en haut, bouton « Bâtiment » à gauche,
# boutons « Véhicule » et « Personnel » à droite, messages éphémères et fenêtre de dialogue.
extends CanvasLayer

signal build_pressed
signal vehicle_pressed
signal staff_pressed

const Dialog = preload("res://scripts/dialog.gd")

const TEXT := Color("#f4f7fb")
const OUTLINE := Color("#10183a")
const GOLD := Color("#f2c230")

var dialog: Dialog
var build_button: Button
var vehicle_button: Button
var staff_button: Button

var _money: Label
var _status: Label
var _hint: Label
var _toast: Label
var _toast_tween: Tween


func _ready() -> void:
	var title := _label("HARBOR HUSTLE", 28, TEXT)
	title.position = Vector2(24, 18)
	add_child(title)
	_money = _label("", 26, GOLD)
	_money.position = Vector2(26, 56)
	add_child(_money)
	_status = _label("", 17, Color("#c9d6f2"))
	_status.position = Vector2(26, 94)
	add_child(_status)

	build_button = _side_button("BÂTIMENT", Color("#2f6fd6"))
	build_button.anchor_top = 0.5
	build_button.anchor_bottom = 0.5
	build_button.offset_left = 20
	build_button.offset_right = 200
	build_button.offset_top = -36
	build_button.offset_bottom = 36
	build_button.pressed.connect(build_pressed.emit)
	add_child(build_button)

	vehicle_button = _side_button("VÉHICULE", Color("#d6402f"))
	staff_button = _side_button("PERSONNEL", Color("#f08a24"))
	for i in 2:
		var button: Button = [vehicle_button, staff_button][i]
		button.anchor_left = 1.0
		button.anchor_right = 1.0
		button.anchor_top = 0.5
		button.anchor_bottom = 0.5
		button.offset_left = -200
		button.offset_right = -20
		button.offset_top = -84 + i * 96
		button.offset_bottom = -12 + i * 96
		add_child(button)
	vehicle_button.pressed.connect(vehicle_pressed.emit)
	staff_button.pressed.connect(staff_pressed.emit)

	_hint = _label("", 18, GOLD)
	_hint.anchor_left = 0.5
	_hint.anchor_right = 0.5
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_left = -400
	_hint.offset_right = 400
	_hint.offset_top = -90
	_hint.offset_bottom = -60
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint)

	_toast = _label("", 22, TEXT)
	_toast.anchor_left = 0.5
	_toast.anchor_right = 0.5
	_toast.offset_left = -400
	_toast.offset_right = 400
	_toast.offset_top = 24
	_toast.offset_bottom = 60
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	add_child(_toast)

	var help := _label("Clic gauche : déplacer le héros / utiliser la console   ·   Molette : zoom   ·   Clic droit ou ZQSD : déplacer la vue", 16, Color("#c9d6f2"))
	help.anchor_top = 1.0
	help.anchor_bottom = 1.0
	help.offset_left = 24
	help.offset_top = -44
	help.offset_bottom = -16
	add_child(help)

	dialog = Dialog.new()
	add_child(dialog)


func set_money(amount: int) -> void:
	_money.text = format_money(amount)


func set_status(text: String) -> void:
	_status.text = text


func set_counts(trucks: int, dockers: int) -> void:
	vehicle_button.text = "VÉHICULE\nCamions : %d" % trucks
	staff_button.text = "PERSONNEL\nDockers : %d" % dockers


# Consigne affichée en bas de l'écran (pendant un placement par exemple) ; vide pour l'effacer.
func set_hint(text: String) -> void:
	_hint.text = text


# Message qui s'affiche quelques secondes en haut de l'écran.
func toast(text: String) -> void:
	_toast.text = text
	if _toast_tween != null:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.5)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


# 100000 -> « 100 000 € »
static func format_money(amount: int) -> String:
	var digits := str(absi(amount))
	var out := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			out += " "
		out += digits[i]
	return ("-" if amount < 0 else "") + out + " €"


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", OUTLINE)
	label.add_theme_constant_override("outline_size", 6)
	return label


func _side_button(text: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_disabled_color", Color("#7f8aa8"))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = color
		match state:
			"hover":
				style.bg_color = color.lightened(0.15)
			"pressed":
				style.bg_color = color.darkened(0.2)
			"disabled":
				style.bg_color = Color("#2a3150")
		style.border_color = OUTLINE
		style.set_border_width_all(3)
		style.set_corner_radius_all(10)
		button.add_theme_stylebox_override(state, style)
	return button

extends Control

var game: Node3D
var font := ThemeDB.fallback_font
const INK := Color("e9eee7")
const MUTED := Color("9eafb3")
const LIME := Color("c0f779")
const PANEL := Color(0.055, 0.085, 0.10, 0.92)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func words(at: Vector2, value: String, size_px: int = 20, color: Color = INK) -> void:
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func panel(rect: Rect2, color: Color = PANEL) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	draw_style_box(style, rect)

func _draw() -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.car):
		return
	var w := size.x
	var h := size.y
	var car = game.car
	panel(Rect2(28, 26, 310, 91))
	words(Vector2(49, 54), "LITTLE DRIFT CLUB", 15, LIME)
	words(Vector2(48, 91), "CHODOV", 33)
	words(Vector2(227, 90), "PRAHA 11", 13, MUTED)
	panel(Rect2(w - 273, 26, 245, 91))
	words(Vector2(w - 252, 53), "SESSION SCORE", 13, MUTED)
	words(Vector2(w - 253, 91), "%06d" % int(game.total_score), 32, LIME)
	panel(Rect2(28, h - 137, 348, 109))
	words(Vector2(48, h - 67), "%03d" % int(car.speed_kmh), 52)
	words(Vector2(155, h - 69), "KM/H", 14, MUTED)
	words(Vector2(48, h - 46), "T8  /  BLACK EDITION", 12, MUTED)
	words(Vector2(226, h - 103), "STEERING", 12, MUTED)
	words(Vector2(225, h - 69), "%02d°" % int(absf(rad_to_deg(car.steer))), 29, LIME)
	draw_line(Vector2(227, h - 49), Vector2(349, h - 49), Color("48565a"), 3)
	draw_circle(Vector2(288 + car.steer / (PI / 2) * 61, h - 49), 5, LIME)
	# North-up schematic: the dot uses the actual world position.
	var center := Vector2(w - 123, h - 123)
	panel(Rect2(w - 220, h - 237, 192, 209))
	words(Vector2(w - 201, h - 210), "5 KM OUTER LOOP", 12, MUTED)
	draw_arc(center, 77, 0, TAU, 100, Color("839398"), 7, true)
	draw_arc(center, 30.5, 0, TAU, 64, Color("839398"), 4, true)
	for axis in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		draw_line(center + axis * 30, center + axis * 77, Color("839398"), 3)
	draw_rect(Rect2(center - Vector2(13, 8), Vector2(26, 16)), Color("f3aa7a"))
	var dot: Vector2 = center + Vector2(car.position.x, car.position.z) * (77.0 / ChodovMap.RING_RADIUS)
	draw_circle(dot, 4.5, LIME)
	var dir: Vector2 = Vector2(-sin(car.heading), -cos(car.heading))
	draw_line(dot, dot + dir * 11, LIME, 2, true)
	words(Vector2(w - 53, h - 184), "N", 11, MUTED)
	if car.drift_active and game.playing:
		panel(Rect2(w / 2 - 142, 33, 284, 87))
		words(Vector2(w / 2 - 119, 61), "SIDEWAYS  /  %02d°" % int(car.slip_angle), 15, LIME)
		words(Vector2(w / 2 - 119, 99), "+%04d" % int(game.chain_score), 29)
		words(Vector2(w / 2 + 62, 98), "×%.1f" % game.multiplier, 22, LIME)
	if game.notice_timer > 0:
		words(Vector2(w / 2 - 125, h - 112), game.notice, 20, LIME)
	panel(Rect2(390, h - 78, 638, 50))
	words(Vector2(408, h - 46), "WASD  drive     SPACE  slide     R  reset     C  camera     ESC  pause", 14, INK)
	if not game.playing:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.065, 0.085, 0.55))
		var x := w / 2 - 310
		var y := h / 2 - 240
		panel(Rect2(x, y, 620, 480), Color(0.055, 0.085, 0.10, 0.98))
		words(Vector2(x + 38, y + 46), "A TINY CAR. A BIG SLIDE.", 14, LIME)
		words(Vector2(x + 34, y + 111), "CHODOV", 64)
		words(Vector2(x + 38, y + 145), "L I T T L E   D R I F T   C L U B", 19, MUTED)
		words(Vector2(x + 38, y + 195), "A black T8-inspired mini sedan. Almost no grip.", 19)
		words(Vector2(x + 38, y + 225), "5 km around a playful slice of Prague.", 19)
		words(Vector2(x + 38, y + 273), "W / ↑   accelerate      S / ↓   brake / reverse", 17, MUTED)
		words(Vector2(x + 38, y + 302), "A / D   steer to 90°     SPACE   extra slide", 17, MUTED)
		words(Vector2(x + 38, y + 331), "R   reset     C   camera     M   sound     ESC   pause", 17, MUTED)
		panel(Rect2(x + 36, y + 356, 548, 58), LIME)
		words(Vector2(x + 122, y + 394), "ENTER  /  " + ("KEEP SLIDING" if game.has_started else "LET'S SLIDE"), 23, Color("172629"))
		words(Vector2(x + 38, y + 450), "Stylized map · not a navigation replica    /    Q to quit", 13, MUTED)

extends RefCounted
## Glass / neon UI helpers — dark navy, cyan rim, soft bloom shadows.

const CYAN := Color(0.35, 0.92, 1.0)
const MAGENTA := Color(1.0, 0.45, 0.78)
const CORAL := Color(1.0, 0.48, 0.32)
const GLASS_BG := Color(0.07, 0.08, 0.16, 0.72)
const DEEP := Color(0.04, 0.03, 0.1)

static func glass_panel(
	bg: Color = GLASS_BG,
	radius: float = 28.0,
	border: Color = Color(0.45, 0.9, 1.0, 0.45),
	glow: Color = Color(0.2, 0.75, 1.0, 0.28)
) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(int(radius))
	s.set_border_width_all(2)
	s.border_color = border
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	s.shadow_color = glow
	s.shadow_size = 18
	s.shadow_offset = Vector2(0, 0)
	return s

static func panel(bg: Color, radius: float = 20.0, border: Color = Color(1, 1, 1, 0.1)) -> StyleBoxFlat:
	return glass_panel(bg, radius, border, Color(border.r, border.g, border.b, 0.22))

static func apply_button(
	b: Button,
	bg: Color,
	border: Color,
	font_color: Color = Color.WHITE,
	font_size: int = 20,
	radius: float = 22.0
) -> void:
	var glow := Color(border.r, border.g, border.b, 0.32)
	var normal := glass_panel(bg, radius, border, glow)
	var hover := glass_panel(bg.lightened(0.1), radius, border.lightened(0.15), Color(border.r, border.g, border.b, 0.45))
	var pressed := glass_panel(bg.darkened(0.1), radius, border, Color(border.r, border.g, border.b, 0.2))
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_stylebox_override("disabled", glass_panel(Color(0.08, 0.09, 0.14, 0.55), radius, Color(0.35, 0.4, 0.5, 0.25), Color(0, 0, 0, 0.1)))
	b.add_theme_color_override("font_color", font_color)
	b.add_theme_color_override("font_hover_color", font_color)
	b.add_theme_color_override("font_pressed_color", font_color.darkened(0.05))
	b.add_theme_color_override("font_disabled_color", Color(0.55, 0.6, 0.7, 0.7))
	b.add_theme_font_size_override("font_size", font_size)

static func label_outline(
	l: Label,
	color: Color,
	size: int,
	outline: Color = Color(0.02, 0.02, 0.08, 0.75),
	outline_size: int = 6
) -> void:
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", outline)
	l.add_theme_constant_override("outline_size", outline_size)

static func pill_label(text: String, color: Color, size: int = 14) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_outline(l, color, size, Color(0.02, 0.02, 0.08, 0.7), 4)
	return l

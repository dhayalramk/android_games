extends RefCounted
## Neon arcade UI helpers for Neon Tac Blitz.

static func panel(bg: Color, radius: float = 20.0, border: Color = Color(1, 1, 1, 0.1)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(int(radius))
	s.set_border_width_all(2)
	s.border_color = border
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 4)
	return s

static func apply_button(b: Button, bg: Color, border: Color, font_color: Color = Color.WHITE, font_size: int = 20) -> void:
	var normal := panel(bg, 18.0, border)
	var hover := panel(bg.lightened(0.08), 18.0, border.lightened(0.2))
	var pressed := panel(bg.darkened(0.12), 18.0, border)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_color_override("font_color", font_color)
	b.add_theme_color_override("font_hover_color", font_color)
	b.add_theme_color_override("font_pressed_color", font_color.darkened(0.05))
	b.add_theme_font_size_override("font_size", font_size)

static func label_outline(l: Label, color: Color, size: int, outline: Color = Color(0, 0, 0, 0.65), outline_size: int = 6) -> void:
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", outline)
	l.add_theme_constant_override("outline_size", outline_size)

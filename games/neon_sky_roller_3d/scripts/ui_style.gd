extends RefCounted
## Play-Store-ish UI helpers — rounded cards, neon CTAs, not default gray Godot.

static func panel(bg: Color, radius: float = 22.0, border: Color = Color(1, 1, 1, 0.08)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(int(radius))
	s.set_border_width_all(2)
	s.border_color = border
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 4)
	return s

static func btn(bg: Color, border: Color, radius: float = 18.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(int(radius))
	s.set_border_width_all(2)
	s.border_color = border
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	s.shadow_color = Color(0, 0, 0, 0.28)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 3)
	return s

static func apply_button(b: Button, bg: Color, border: Color, font_color: Color = Color.WHITE, font_size: int = 18) -> void:
	var normal := btn(bg, border)
	var hover := btn(bg.lightened(0.08), border.lightened(0.15))
	var pressed := btn(bg.darkened(0.1), border)
	var disabled := btn(Color(0.15, 0.16, 0.2, 0.7), Color(0.3, 0.3, 0.35, 0.5))
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_color_override("font_color", font_color)
	b.add_theme_color_override("font_hover_color", font_color)
	b.add_theme_color_override("font_pressed_color", font_color.darkened(0.05))
	b.add_theme_color_override("font_disabled_color", Color(0.65, 0.65, 0.7, 0.7))
	b.add_theme_font_size_override("font_size", font_size)

static func label_outline(l: Label, color: Color, size: int, outline: Color = Color(0, 0, 0, 0.65), outline_size: int = 6) -> void:
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", outline)
	l.add_theme_constant_override("outline_size", outline_size)

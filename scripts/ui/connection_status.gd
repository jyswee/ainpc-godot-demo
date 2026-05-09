extends Label

func _ready() -> void:
	text = "Connecting..."
	add_theme_color_override("font_color", Color.YELLOW)
	GameManager.connection_status_changed.connect(_on_status_changed)

func _on_status_changed(connected: bool) -> void:
	if connected:
		text = "API Connected"
		add_theme_color_override("font_color", Color.GREEN)
		# Fade out after 3 seconds
		var tween = create_tween()
		tween.tween_interval(3.0)
		tween.tween_property(self, "modulate:a", 0.0, 1.0)
	else:
		text = "API Offline"
		add_theme_color_override("font_color", Color.RED)
		modulate.a = 1.0

extends CanvasLayer
## Minimal HUD that works in both the 3D and 2D scenes: health, scrap counter,
## level timer, a "pursued" warning and a death banner. Builds itself in code.

var _health_bar: ProgressBar
var _health_label: Label
var _collect_label: Label
var _time_label: Label
var _stalker_label: Label
var _death_label: Label

var _elapsed := 0.0
var _is_dead := false


func _ready() -> void:
	_build_ui()

	GameState.health_changed.connect(_on_health_changed)
	GameState.collectible_count_changed.connect(_on_collectibles_changed)
	GameState.stalker_activated.connect(_on_stalker_activated)
	GameState.player_died.connect(_on_player_died)

	_on_health_changed(GameState.current_health, GameState.max_health)
	_on_collectibles_changed(GameState.collectibles)
	if GameState.stalker_active:
		_on_stalker_activated()


func _process(delta: float) -> void:
	if _is_dead:
		return
	_elapsed += delta
	_time_label.text = "TIME %s" % _format_time(_elapsed)


func _format_time(seconds_total: float) -> String:
	var minutes := int(seconds_total) / 60
	var seconds := int(seconds_total) % 60
	var tenths := int(fmod(seconds_total, 1.0) * 10.0)
	return "%02d:%02d.%d" % [minutes, seconds, tenths]


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)

	_health_label = Label.new()
	_health_label.text = "HP"
	row.add_child(_health_label)

	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(180, 18)
	_health_bar.show_percentage = false
	row.add_child(_health_bar)

	_collect_label = Label.new()
	box.add_child(_collect_label)

	_time_label = Label.new()
	_time_label.text = "TIME 00:00.0"
	box.add_child(_time_label)

	_stalker_label = Label.new()
	_stalker_label.text = "!! PURSUED !!"
	_stalker_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	_stalker_label.add_theme_font_size_override("font_size", 22)
	_stalker_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_stalker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stalker_label.visible = false
	add_child(_stalker_label)

	_death_label = Label.new()
	_death_label.text = "You Died"
	_death_label.add_theme_font_size_override("font_size", 40)
	_death_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_death_label.visible = false
	add_child(_death_label)


func _on_health_changed(current_health: int, max_health: int) -> void:
	_health_bar.max_value = max_health
	_health_bar.value = current_health
	_health_label.text = "HP %d/%d" % [current_health, max_health]

	var ratio := float(current_health) / float(max_health) if max_health > 0 else 0.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.3, 0.85, 0.35).lerp(Color(0.92, 0.25, 0.25), 1.0 - ratio)
	fill.set_corner_radius_all(4)
	_health_bar.add_theme_stylebox_override("fill", fill)


func _on_collectibles_changed(count: int) -> void:
	_collect_label.text = "Scrap: %d" % count


func _on_stalker_activated() -> void:
	_stalker_label.visible = true


func _on_player_died() -> void:
	_is_dead = true
	_death_label.visible = true

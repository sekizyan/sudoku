class_name OverlayManager
extends RefCounted

const FONT_SIZE_SETTINGS_LABEL := 36
const FONT_SIZE_STATS_TITLE := 28
const FONT_SIZE_STATS_DETAIL := 22
const TOGGLE_TRACK_W := 81
const TOGGLE_TRACK_H := 41
const TOGGLE_KNOB_SIZE := 31
const TOGGLE_KNOB_MARGIN := 5
const CORNER_RADIUS_TOGGLE := 21

var g

var win_overlay : ColorRect
var win_content : VBoxContainer
var win_time_label : Label
var win_mistakes_label : Label
var win_best_label : Label
var win_streak_label : Label
var win_best_streak_label : Label
var lose_overlay : ColorRect
var pause_overlay : ColorRect
var settings_overlay : ColorRect
var stats_overlay : ColorRect
var stats_container : VBoxContainer
var difficulty_overlay : ColorRect
var continue_btn : Button
var daily_btn : Button
var daily_streak_label : Label
var theme_toggle_track : Panel
var theme_toggle_knob : Panel
var validation_overlay : ColorRect
var validation_error_label : Label

func setup(host) -> void:
	g = host

func create_all() -> void:
	create_win_overlay()
	create_lose_overlay()
	create_pause_overlay()
	create_difficulty_overlay()
	create_settings_overlay()
	create_stats_overlay()
	create_validation_overlay()

func apply_theme() -> void:
	win_overlay.color = g.theme_mgr.color_overlay
	lose_overlay.color = g.theme_mgr.color_overlay
	pause_overlay.color = g.theme_mgr.color_overlay
	settings_overlay.color = g.theme_mgr.color_overlay_solid
	stats_overlay.color = g.theme_mgr.color_overlay_solid
	difficulty_overlay.color = g.theme_mgr.color_overlay_solid

	for overlay in [win_overlay, lose_overlay, pause_overlay, settings_overlay, stats_overlay, difficulty_overlay, validation_overlay]:
		g.theme_mgr.theme_overlay_children(overlay)

	validation_overlay.color = g.theme_mgr.color_overlay
	update_daily_button()


# --- Overlay Creation ---

func create_win_overlay() -> void:
	var result = UIFactory.create_overlay(g)
	win_overlay = result[0]
	win_content = result[1]

	win_content.add_child(UIFactory.create_overlay_label("You Won!!"))

	var stats_box := VBoxContainer.new()
	stats_box.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_box.add_theme_constant_override("separation", 8)

	win_time_label = UIFactory.create_overlay_label("", 32)
	stats_box.add_child(win_time_label)

	win_mistakes_label = UIFactory.create_overlay_label("", 32)
	stats_box.add_child(win_mistakes_label)

	win_best_label = UIFactory.create_overlay_label("", FONT_SIZE_STATS_TITLE)
	win_best_label.visible = false
	stats_box.add_child(win_best_label)

	win_streak_label = UIFactory.create_overlay_label("", FONT_SIZE_STATS_TITLE)
	win_streak_label.visible = false
	stats_box.add_child(win_streak_label)

	win_best_streak_label = UIFactory.create_overlay_label("", FONT_SIZE_STATS_DETAIL)
	win_best_streak_label.visible = false
	stats_box.add_child(win_best_streak_label)

	win_content.add_child(stats_box)
	win_content.add_child(UIFactory.create_overlay_button("New Game", _go_to_difficulty.bind(win_overlay)))

func create_lose_overlay() -> void:
	var result = UIFactory.create_overlay(g)
	lose_overlay = result[0]
	var vbox = result[1]

	vbox.add_child(UIFactory.create_overlay_label("You Lost"))
	var ad_life_btn := UIFactory.create_overlay_button("Watch Ad for Life", _on_another_life_pressed)
	ad_life_btn.name = "AdLifeButton"
	vbox.add_child(ad_life_btn)
	vbox.add_child(UIFactory.create_overlay_button("New Game", _go_to_difficulty.bind(lose_overlay)))

func create_pause_overlay() -> void:
	var result = UIFactory.create_overlay(g)
	pause_overlay = result[0]
	var vbox = result[1]

	vbox.add_child(UIFactory.create_overlay_label("Paused"))
	vbox.add_child(UIFactory.create_overlay_button("Resume", _on_resume_pressed))
	vbox.add_child(UIFactory.create_overlay_button("Restart", _on_restart_pressed))
	vbox.add_child(UIFactory.create_overlay_button("New Game", _go_to_difficulty.bind(pause_overlay)))

func create_settings_overlay() -> void:
	var result = UIFactory.create_overlay(g, Color(0, 0, 0, 1.0))
	settings_overlay = result[0]
	var vbox = result[1]

	settings_overlay.add_child(UIFactory.create_close_button(_on_settings_close_pressed))

	vbox.add_child(UIFactory.create_overlay_label("Settings"))

	var theme_row := HBoxContainer.new()
	theme_row.alignment = BoxContainer.ALIGNMENT_CENTER
	theme_row.add_theme_constant_override("separation", 20)

	var theme_label := Label.new()
	theme_label.text = "Dark Mode"
	theme_label.add_theme_font_size_override("font_size", FONT_SIZE_SETTINGS_LABEL)
	theme_label.add_theme_color_override("font_color", Color.WHITE)
	theme_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	theme_row.add_child(theme_label)

	var toggle_container := Control.new()
	toggle_container.custom_minimum_size = Vector2(TOGGLE_TRACK_W, TOGGLE_TRACK_H)
	toggle_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var track_style := StyleBoxFlat.new()
	track_style.corner_radius_top_left = CORNER_RADIUS_TOGGLE
	track_style.corner_radius_top_right = CORNER_RADIUS_TOGGLE
	track_style.corner_radius_bottom_left = CORNER_RADIUS_TOGGLE
	track_style.corner_radius_bottom_right = CORNER_RADIUS_TOGGLE

	theme_toggle_track = Panel.new()
	theme_toggle_track.size = Vector2(TOGGLE_TRACK_W, TOGGLE_TRACK_H)
	theme_toggle_track.add_theme_stylebox_override("panel", track_style)
	toggle_container.add_child(theme_toggle_track)

	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color.WHITE
	knob_style.corner_radius_top_left = 15
	knob_style.corner_radius_top_right = 15
	knob_style.corner_radius_bottom_left = 15
	knob_style.corner_radius_bottom_right = 15

	theme_toggle_knob = Panel.new()
	theme_toggle_knob.size = Vector2(TOGGLE_KNOB_SIZE, TOGGLE_KNOB_SIZE)
	theme_toggle_knob.add_theme_stylebox_override("panel", knob_style)
	theme_toggle_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toggle_container.add_child(theme_toggle_knob)

	update_toggle_visual()

	var toggle_btn := Button.new()
	toggle_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	toggle_btn.focus_mode = Control.FOCUS_NONE
	toggle_btn.flat = true
	toggle_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	toggle_btn.pressed.connect(_on_theme_toggle_pressed)
	toggle_container.add_child(toggle_btn)

	theme_row.add_child(toggle_container)
	vbox.add_child(theme_row)
	vbox.add_child(UIFactory.create_overlay_button("Statistics", _on_statistics_pressed))

func create_stats_overlay() -> void:
	var result = UIFactory.create_overlay(g, Color(0, 0, 0, 1.0), 20)
	stats_overlay = result[0]
	var vbox = result[1]

	stats_overlay.add_child(UIFactory.create_close_button(_on_stats_back_pressed))

	vbox.add_child(UIFactory.create_overlay_label("Statistics", 48))

	stats_container = VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 12)
	vbox.add_child(stats_container)

	vbox.add_child(UIFactory.create_overlay_button("Back", _on_stats_back_pressed))

func create_difficulty_overlay() -> void:
	var result = UIFactory.create_overlay(g, Color(0, 0, 0, 1.0), 24)
	difficulty_overlay = result[0]
	var vbox = result[1]

	vbox.add_child(UIFactory.create_overlay_label("Select Difficulty", 52))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(spacer)

	continue_btn = UIFactory.create_overlay_button("Continue", _on_continue_pressed)
	continue_btn.custom_minimum_size = Vector2(340, 72)
	continue_btn.add_theme_font_size_override("font_size", 32)
	continue_btn.visible = false
	vbox.add_child(continue_btn)

	var daily_section := VBoxContainer.new()
	daily_section.alignment = BoxContainer.ALIGNMENT_CENTER
	daily_section.add_theme_constant_override("separation", 8)

	daily_btn = UIFactory.create_overlay_button("Daily Puzzle", _on_daily_pressed)
	daily_btn.custom_minimum_size = Vector2(340, 72)
	daily_btn.add_theme_font_size_override("font_size", 32)
	daily_section.add_child(daily_btn)

	daily_streak_label = Label.new()
	daily_streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	daily_streak_label.add_theme_font_size_override("font_size", FONT_SIZE_STATS_DETAIL)
	daily_section.add_child(daily_streak_label)

	vbox.add_child(daily_section)

	for diff_name in g.DIFFICULTIES:
		var btn = UIFactory.create_overlay_button(diff_name, _on_difficulty_selected.bind(diff_name, g.DIFFICULTIES[diff_name]))
		btn.custom_minimum_size = Vector2(340, 72)
		btn.add_theme_font_size_override("font_size", 32)
		vbox.add_child(btn)

	var create_spacer := Control.new()
	create_spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(create_spacer)

	var create_btn = UIFactory.create_overlay_button("Create Your Own", g.custom.on_create_puzzle_pressed)
	create_btn.custom_minimum_size = Vector2(340, 72)
	create_btn.add_theme_font_size_override("font_size", 32)
	vbox.add_child(create_btn)

func create_validation_overlay() -> void:
	var result = UIFactory.create_overlay(g)
	validation_overlay = result[0]
	var vbox = result[1]

	validation_error_label = UIFactory.create_overlay_label("", 32)
	vbox.add_child(validation_error_label)
	vbox.add_child(UIFactory.create_overlay_button("Back", _on_validation_back))


# --- Overlay Callbacks ---

func _go_to_difficulty(overlay: ColorRect) -> void:
	overlay.visible = false
	g.game_container.visible = false
	difficulty_overlay.visible = true
	g.custom.is_custom_game = false
	g.custom.is_creating_puzzle = false
	g.custom.enter_solve_mode()
	g.save_mgr.clear()
	update_continue_button()
	update_daily_button()

func on_pause_pressed() -> void:
	g.timer_running = false
	pause_overlay.visible = true
	g.save_mgr.save_immediate()

func _on_resume_pressed() -> void:
	pause_overlay.visible = false
	g.timer_running = true

func _on_restart_pressed() -> void:
	pause_overlay.visible = false
	g.player_board = g.initial_board.duplicate(true)
	g._reset_game_state()
	g.update_ui()
	g.refresh_board_styles()
	g.save_mgr.request_save()

func on_settings_pressed() -> void:
	g.timer_running = false
	g.settings_button.visible = false
	settings_overlay.visible = true

func _on_settings_close_pressed() -> void:
	settings_overlay.visible = false
	g.settings_button.visible = true
	if g.timer_started:
		g.timer_running = true

func _on_statistics_pressed() -> void:
	settings_overlay.visible = false
	_update_stats_display()
	stats_overlay.visible = true

func _on_stats_back_pressed() -> void:
	stats_overlay.visible = false
	settings_overlay.visible = true

func _on_theme_toggle_pressed() -> void:
	g.theme_mgr.set_dark_mode(!g.theme_mgr.dark_mode)
	update_toggle_visual()
	g._apply_theme()
	g.stats_mgr.set_dark_mode(g.theme_mgr.dark_mode)
	g.stats_mgr.save_stats()

func update_toggle_visual() -> void:
	var track_style : StyleBoxFlat = theme_toggle_track.get_theme_stylebox("panel")
	if g.theme_mgr.dark_mode:
		track_style.bg_color = Color(0.3, 0.7, 0.4)
		theme_toggle_knob.position = Vector2(TOGGLE_TRACK_W - TOGGLE_KNOB_SIZE - TOGGLE_KNOB_MARGIN, TOGGLE_KNOB_MARGIN)
	else:
		track_style.bg_color = Color(0.5, 0.5, 0.5)
		theme_toggle_knob.position = Vector2(TOGGLE_KNOB_MARGIN, TOGGLE_KNOB_MARGIN)

func _update_stats_display() -> void:
	for child in stats_container.get_children():
		child.queue_free()

	g.stats_mgr.init_stats()

	var today = g._get_today_date_str()
	var yesterday = g._get_yesterday_date_str()
	var daily_section := VBoxContainer.new()
	daily_section.add_theme_constant_override("separation", 2)

	var daily_title := Label.new()
	daily_title.text = "Daily"
	daily_title.add_theme_font_size_override("font_size", FONT_SIZE_STATS_TITLE)
	var warm := Color(0.9, 0.75, 0.2) if g.theme_mgr.dark_mode else Color(0.6, 0.4, 0.0)
	daily_title.add_theme_color_override("font_color", warm)
	daily_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	daily_section.add_child(daily_title)

	var streak = g.stats_mgr.get_daily_streak(today, yesterday)
	var best_streak = g.stats_mgr.get_daily_best_streak()
	var daily_best_time = g.stats_mgr.get_daily_best_time()

	var daily_detail := Label.new()
	daily_detail.text = "Streak: %d   Record: %d   Best: %s" % [streak, best_streak, g.stats_mgr.format_best_time(daily_best_time)]
	daily_detail.add_theme_font_size_override("font_size", FONT_SIZE_STATS_DETAIL)
	daily_detail.add_theme_color_override("font_color", g.theme_mgr.color_overlay_label)
	daily_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	daily_section.add_child(daily_detail)

	stats_container.add_child(daily_section)

	for diff_name in g.DIFFICULTIES.keys() + ["Custom"]:
		var entry : Dictionary = g.stats_mgr.stats[diff_name]
		var started := int(entry.get("started", 0))
		var won := int(entry.get("won", 0))
		var best := float(entry.get("best_time", -1.0))

		if diff_name == "Custom" and started == 0 and won == 0:
			continue

		var section := VBoxContainer.new()
		section.add_theme_constant_override("separation", 2)

		var title := Label.new()
		title.text = diff_name
		title.add_theme_font_size_override("font_size", FONT_SIZE_STATS_TITLE)
		title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2) if g.theme_mgr.dark_mode else Color(0.6, 0.4, 0.0))
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		section.add_child(title)

		var detail := Label.new()
		detail.text = "Played: %d   Won: %d   Best: %s" % [started, won, g.stats_mgr.format_best_time(best)]
		detail.add_theme_font_size_override("font_size", FONT_SIZE_STATS_DETAIL)
		detail.add_theme_color_override("font_color", g.theme_mgr.color_overlay_label)
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		section.add_child(detail)

		stats_container.add_child(section)

func _on_continue_pressed() -> void:
	if g._load_game():
		difficulty_overlay.visible = false
		g.game_container.visible = true

func update_continue_button() -> void:
	if not g.save_mgr.has_save():
		continue_btn.visible = false
		return
	var data = g.save_mgr.load_data()
	if data != null and data.get("is_daily", false):
		if data.get("daily_date", "") != g._get_today_date_str():
			g.save_mgr.clear()
			continue_btn.visible = false
			return
	continue_btn.visible = true

func _on_another_life_pressed() -> void:
	AdManager.show_rewarded_ad(_grant_extra_life)

func _grant_extra_life() -> void:
	lose_overlay.visible = false
	g.actions.mistakes = g.LIFE_LIMIT - 1
	g.mistakes_label.text = "Mistakes: %d/%d" % [g.actions.mistakes, g.LIFE_LIMIT]
	g.timer_running = true
	g.save_mgr.request_save()

func _on_difficulty_selected(diff_name: String, remove_count: int) -> void:
	difficulty_overlay.visible = false
	g.game_container.visible = true
	g.difficulty_label.text = "Level: " + diff_name
	g.current_difficulty = diff_name
	g.is_daily_game = false
	g.custom.is_custom_game = false
	g.custom.is_creating_puzzle = false
	g.custom.enter_solve_mode()

	g._reset_game_state()
	g.stats_mgr.record_game_started(diff_name)
	var result = g.solver.generate_puzzle(remove_count)
	g.solution_board = result[0]
	g.player_board = result[1]
	g.initial_board = g.player_board.duplicate(true)
	g.update_ui()
	g.refresh_board_styles()
	g.save_mgr.request_save()

func _on_daily_pressed() -> void:
	var info = g._get_daily_info()
	difficulty_overlay.visible = false
	g.game_container.visible = true
	g.is_daily_game = true
	g.custom.is_custom_game = false
	g.custom.is_creating_puzzle = false
	g.current_difficulty = ""
	g.custom.enter_solve_mode()
	g.difficulty_label.text = "Daily - " + info.difficulty

	g._reset_game_state()
	var result = g.solver.generate_daily_puzzle(info.seed, info.remove_count)
	g.solution_board = result[0]
	g.player_board = result[1]
	g.initial_board = g.player_board.duplicate(true)
	g.update_ui()
	g.refresh_board_styles()
	g.save_mgr.request_save()

func update_daily_button() -> void:
	var today = g._get_today_date_str()
	var yesterday = g._get_yesterday_date_str()
	var completed = g.stats_mgr.is_daily_completed(today)

	if completed:
		daily_btn.text = "Daily Complete ✓"
		daily_btn.disabled = true
	else:
		daily_btn.text = "Daily Puzzle"
		daily_btn.disabled = false

	var streak = g.stats_mgr.get_daily_streak(today, yesterday)
	var warm := Color(0.9, 0.75, 0.2) if g.theme_mgr.dark_mode else Color(0.6, 0.4, 0.0)
	daily_streak_label.add_theme_color_override("font_color", warm)
	if streak > 0:
		daily_streak_label.text = "%d day streak" % streak
	else:
		daily_streak_label.text = "Start your streak!"

func show_validation_error(msg: String) -> void:
	validation_error_label.text = msg
	validation_overlay.visible = true

func _on_validation_back() -> void:
	validation_overlay.visible = false

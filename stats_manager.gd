class_name StatsManager
extends RefCounted

const STATS_PATH := "user://sudoku_stats.json"

var stats := {}
var _difficulty_names: Array = []

func setup(difficulty_names: Array) -> void:
	_difficulty_names = difficulty_names

func init_stats() -> void:
	for diff_name in _difficulty_names:
		if not stats.has(diff_name):
			stats[diff_name] = {"started": 0, "won": 0, "best_time": -1.0}

func load_stats() -> void:
	if not FileAccess.file_exists(STATS_PATH):
		init_stats()
		return

	var file = FileAccess.open(STATS_PATH, FileAccess.READ)
	if not file:
		init_stats()
		return

	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		init_stats()
		return

	stats = json.data
	init_stats()

func save_stats() -> void:
	var file = FileAccess.open(STATS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(stats))

func get_dark_mode() -> bool:
	return bool(stats.get("dark_mode", true))

func set_dark_mode(value: bool) -> void:
	stats["dark_mode"] = value

func record_game_started(diff_name: String) -> void:
	init_stats()
	stats[diff_name]["started"] = int(stats[diff_name]["started"]) + 1
	save_stats()

func record_game_won(diff_name: String, time: float) -> void:
	init_stats()
	stats[diff_name]["won"] = int(stats[diff_name]["won"]) + 1
	var best = float(stats[diff_name]["best_time"])
	if best < 0 or time < best:
		stats[diff_name]["best_time"] = time
	save_stats()

func format_best_time(seconds: float) -> String:
	if seconds < 0:
		return "--:--"
	var mins := int(seconds) / 60
	var secs := int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

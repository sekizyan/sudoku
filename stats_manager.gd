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
	if not stats.has("daily"):
		stats["daily"] = {
			"last_completed": "",
			"current_streak": 0,
			"best_streak": 0,
			"best_time": -1.0,
			"games_won": 0,
		}

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


# --- Daily Streak ---

func is_daily_completed(today: String) -> bool:
	init_stats()
	var daily : Dictionary = stats.get("daily", {})
	return daily.get("last_completed", "") == today

func record_daily_won(today: String, yesterday: String, time: float) -> void:
	init_stats()
	var daily : Dictionary = stats["daily"]
	if daily.get("last_completed", "") == today:
		return

	var last := str(daily.get("last_completed", ""))
	if last == yesterday:
		daily["current_streak"] = int(daily.get("current_streak", 0)) + 1
	else:
		daily["current_streak"] = 1

	daily["last_completed"] = today
	daily["games_won"] = int(daily.get("games_won", 0)) + 1

	if int(daily["current_streak"]) > int(daily.get("best_streak", 0)):
		daily["best_streak"] = daily["current_streak"]

	var best := float(daily.get("best_time", -1.0))
	if best < 0 or time < best:
		daily["best_time"] = time

	save_stats()

func get_daily_streak(today: String, yesterday: String) -> int:
	init_stats()
	var daily : Dictionary = stats.get("daily", {})
	var last := str(daily.get("last_completed", ""))
	if last == today or last == yesterday:
		return int(daily.get("current_streak", 0))
	return 0

func get_daily_best_streak() -> int:
	init_stats()
	return int(stats.get("daily", {}).get("best_streak", 0))

func get_daily_best_time() -> float:
	init_stats()
	return float(stats.get("daily", {}).get("best_time", -1.0))

func get_daily_games_won() -> int:
	init_stats()
	return int(stats.get("daily", {}).get("games_won", 0))

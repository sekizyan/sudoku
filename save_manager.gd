class_name SaveManager
extends Node

const SAVE_PATH := "user://sudoku_save.json"

var _save_timer: Timer
var _data_provider: Callable

func _ready() -> void:
	_save_timer = Timer.new()
	_save_timer.wait_time = 2.0
	_save_timer.one_shot = true
	_save_timer.timeout.connect(_on_save_timeout)
	add_child(_save_timer)

func set_data_provider(provider: Callable) -> void:
	_data_provider = provider

func request_save() -> void:
	_save_timer.start()

func save_immediate() -> void:
	_perform_save()

func _on_save_timeout() -> void:
	_perform_save()

func _perform_save() -> void:
	var data = _data_provider.call()
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_data() -> Variant:
	if not FileAccess.file_exists(SAVE_PATH):
		return null
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return null
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return null
	if not json.data is Dictionary:
		return null
	return json.data

func clear() -> void:
	DirAccess.remove_absolute(SAVE_PATH)

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

static func to_int_board(data: Array) -> Array:
	var result := []
	for r in range(data.size()):
		result.append([])
		for c in range(data[r].size()):
			result[r].append(int(data[r][c]))
	return result

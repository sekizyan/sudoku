extends Node

const REWARDED_AD_UNIT_ID_ANDROID := "ca-app-pub-3940256099942544/5224354917"
const REWARDED_AD_UNIT_ID_IOS := "ca-app-pub-3940256099942544/1712485313"

var _rewarded_plugin: Object
var _reward_callback: Callable
var _ad_uid := -1
var _ad_ready := false

func _ready() -> void:
	if not _is_mobile():
		return

	if not Engine.has_singleton("PoingGodotAdMob") or not Engine.has_singleton("PoingGodotAdMobRewardedAd"):
		return

	_rewarded_plugin = Engine.get_singleton("PoingGodotAdMobRewardedAd")
	_rewarded_plugin.connect("on_rewarded_ad_loaded", _on_ad_loaded)
	_rewarded_plugin.connect("on_rewarded_ad_failed_to_load", _on_ad_failed_to_load)
	_rewarded_plugin.connect("on_rewarded_ad_user_earned_reward", _on_user_earned_reward)
	_rewarded_plugin.connect("on_rewarded_ad_dismissed_full_screen_content", _on_ad_dismissed)
	_rewarded_plugin.connect("on_rewarded_ad_failed_to_show_full_screen_content", _on_ad_failed_to_show)

	var main_plugin := Engine.get_singleton("PoingGodotAdMob")
	main_plugin.initialize()

	if not main_plugin.is_connected("on_initialization_complete", _on_init_complete):
		main_plugin.connect("on_initialization_complete", _on_init_complete)

	get_tree().create_timer(5.0).timeout.connect(func():
		if not _ad_ready and _ad_uid == -1:
			_load_ad()
	)

func _on_init_complete(_status: Dictionary) -> void:
	_load_ad()

func _load_ad() -> void:
	if _rewarded_plugin == null:
		return

	var unit_id := ""
	if OS.get_name() == "Android":
		unit_id = REWARDED_AD_UNIT_ID_ANDROID
	elif OS.get_name() == "iOS":
		unit_id = REWARDED_AD_UNIT_ID_IOS

	_ad_uid = _rewarded_plugin.create()
	_ad_ready = false

	var ad_request := {
		"mediation_extras": {},
		"extras": {},
		"google_request_agent": "Godot-PoingStudios"
	}
	_rewarded_plugin.load(unit_id, ad_request, [], _ad_uid)

func _on_ad_loaded(uid: int) -> void:
	if uid == _ad_uid:
		_ad_ready = true

func _on_ad_failed_to_load(uid: int, _error: Dictionary) -> void:
	if uid == _ad_uid:
		_ad_ready = false
		get_tree().create_timer(10.0).timeout.connect(func(): _load_ad())

func _on_user_earned_reward(uid: int, _reward: Dictionary) -> void:
	if uid == _ad_uid:
		if _reward_callback.is_valid():
			_reward_callback.call()
			_reward_callback = Callable()

func _on_ad_dismissed(uid: int) -> void:
	if uid == _ad_uid:
		_ad_ready = false
		_load_ad()

func _on_ad_failed_to_show(uid: int, _error: Dictionary) -> void:
	if uid == _ad_uid:
		_ad_ready = false
		_load_ad()

func show_rewarded_ad(reward_callback: Callable) -> void:
	if not _is_mobile():
		reward_callback.call()
		return

	if _ad_ready and _rewarded_plugin != null:
		_reward_callback = reward_callback
		_rewarded_plugin.show(_ad_uid)
	else:
		_load_ad()

func is_rewarded_ad_ready() -> bool:
	if not _is_mobile():
		return true
	return _ad_ready

func _is_mobile() -> bool:
	return OS.get_name() in ["Android", "iOS"]

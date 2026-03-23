class_name AdSystem
extends RefCounted

# IDs de producao
const REVIVE_AD_ID_PROD := "ca-app-pub-9962376365131216/9375567454"
const DOUBLE_AD_ID_PROD := "ca-app-pub-9962376365131216/9519037686"
# IDs de teste do Google
const REVIVE_AD_ID_TEST := "ca-app-pub-3940256099942544/5224354917"
const DOUBLE_AD_ID_TEST := "ca-app-pub-3940256099942544/5224354917"

# Troca pra _PROD quando for publicar
var REVIVE_AD_ID := REVIVE_AD_ID_PROD
var DOUBLE_AD_ID := DOUBLE_AD_ID_PROD

var revive_used := false
var shop_ads_shown := 0
const MAX_SHOP_ADS := 2

var _ads: Dictionary = {}  # ad_id -> RewardedAd
var _pending_callback: Callable
var _pending_fail_callback: Callable
var _is_mobile := false
var _initialized := false

func _init() -> void:
	_is_mobile = OS.get_name() in ["Android", "iOS"]
	if _is_mobile:
		var listener := OnInitializationCompleteListener.new()
		listener.on_initialization_complete = func(_status) -> void:
			_initialized = true
			print("[AdSystem] MobileAds initialized")
			_preload_ad(REVIVE_AD_ID)
			_preload_ad(DOUBLE_AD_ID)
		MobileAds.initialize(listener)

func can_revive() -> bool:
	return not revive_used

func use_revive() -> void:
	revive_used = true

func can_show_shop_ad() -> bool:
	return shop_ads_shown < MAX_SHOP_ADS

func use_shop_ad() -> void:
	shop_ads_shown += 1

func reset_run() -> void:
	revive_used = false
	shop_ads_shown = 0
	if _is_mobile and _initialized:
		_preload_ad(REVIVE_AD_ID)
		_preload_ad(DOUBLE_AD_ID)

func show_rewarded_ad(callback: Callable, ad_id: String = REVIVE_AD_ID, on_fail: Callable = Callable()) -> void:
	if not _is_mobile:
		callback.call()
		return
	if _ads.has(ad_id) and _ads[ad_id] != null:
		_show_loaded_ad(ad_id, callback, on_fail)
	else:
		print("[AdSystem] Ad not preloaded, loading now...")
		_pending_callback = callback
		_pending_fail_callback = on_fail
		_load_ad(ad_id, true)

func _preload_ad(ad_id: String) -> void:
	_load_ad(ad_id, false)

func _load_ad(ad_id: String, show_when_ready: bool) -> void:
	var load_cb := RewardedAdLoadCallback.new()
	load_cb.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		print("[AdSystem] Failed to load %s: %s" % [ad_id, error.message])
		if show_when_ready:
			if _pending_fail_callback.is_valid():
				_pending_fail_callback.call()
			_pending_callback = Callable()
			_pending_fail_callback = Callable()
	load_cb.on_ad_loaded = func(ad: RewardedAd) -> void:
		print("[AdSystem] Ad loaded: %s" % ad_id)
		_ads[ad_id] = ad
		if show_when_ready and _pending_callback.is_valid():
			_show_loaded_ad(ad_id, _pending_callback, _pending_fail_callback)
			_pending_callback = Callable()
			_pending_fail_callback = Callable()
	RewardedAdLoader.new().load(ad_id, AdRequest.new(), load_cb)

func _show_loaded_ad(ad_id: String, callback: Callable, on_fail: Callable) -> void:
	var ad: RewardedAd = _ads[ad_id]
	_ads[ad_id] = null
	var state := {"earned": false}

	var content_cb := FullScreenContentCallback.new()
	content_cb.on_ad_dismissed_full_screen_content = func() -> void:
		print("[AdSystem] Ad dismissed, earned=%s" % str(state.earned))
		ad.destroy()
		_preload_ad(ad_id)
		if state.earned:
			callback.call()
	content_cb.on_ad_failed_to_show_full_screen_content = func(err: AdError) -> void:
		print("[AdSystem] Failed to show: " + err.message)
		ad.destroy()
		_preload_ad(ad_id)
		if on_fail.is_valid():
			on_fail.call()
	ad.full_screen_content_callback = content_cb

	var reward_listener := OnUserEarnedRewardListener.new()
	reward_listener.on_user_earned_reward = func(_item: RewardedItem) -> void:
		print("[AdSystem] Reward earned")
		state.earned = true
	ad.show(reward_listener)

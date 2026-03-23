class_name AdSystem
extends RefCounted

const REVIVE_AD_ID := "ca-app-pub-9962376365131216/9375567454"
const DOUBLE_AD_ID := "ca-app-pub-9962376365131216/9519037686"

var revive_used := false
var shop_ads_shown := 0
const MAX_SHOP_ADS := 2

var _rewarded_ad: RewardedAd
var _pending_callback: Callable
var _is_mobile := false
var _initialized := false

func _init() -> void:
	_is_mobile = OS.get_name() in ["Android", "iOS"]
	if _is_mobile:
		var listener := OnInitializationCompleteListener.new()
		listener.on_initialization_complete = func(_status) -> void:
			_initialized = true
			print("[AdSystem] MobileAds initialized")
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

func show_rewarded_ad(callback: Callable, ad_id: String = REVIVE_AD_ID) -> void:
	if not _is_mobile:
		# Desktop mock — executa callback imediatamente
		callback.call()
		return
	_pending_callback = callback
	_load_and_show(ad_id)

func _load_and_show(ad_id: String) -> void:
	if _rewarded_ad:
		_rewarded_ad.destroy()
		_rewarded_ad = null

	var load_cb := RewardedAdLoadCallback.new()
	load_cb.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		print("[AdSystem] Failed to load: " + error.message)
		_pending_callback = Callable()
	load_cb.on_ad_loaded = func(ad: RewardedAd) -> void:
		print("[AdSystem] Ad loaded")
		_rewarded_ad = ad

		var content_cb := FullScreenContentCallback.new()
		content_cb.on_ad_dismissed_full_screen_content = func() -> void:
			print("[AdSystem] Ad dismissed")
			_destroy_ad()
		content_cb.on_ad_failed_to_show_full_screen_content = func(err: AdError) -> void:
			print("[AdSystem] Failed to show: " + err.message)
			_pending_callback = Callable()
			_destroy_ad()
		ad.full_screen_content_callback = content_cb

		# Mostra o ad
		var reward_listener := OnUserEarnedRewardListener.new()
		reward_listener.on_user_earned_reward = func(_item: RewardedItem) -> void:
			print("[AdSystem] Reward earned")
			if _pending_callback.is_valid():
				_pending_callback.call()
				_pending_callback = Callable()
		ad.show(reward_listener)

	RewardedAdLoader.new().load(ad_id, AdRequest.new(), load_cb)

func _destroy_ad() -> void:
	if _rewarded_ad:
		_rewarded_ad.destroy()
		_rewarded_ad = null

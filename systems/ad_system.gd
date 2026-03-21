class_name AdSystem
extends RefCounted

signal ad_completed
signal ad_failed

var revive_used := false
var shop_ads_shown := 0
const MAX_SHOP_ADS := 2

# Mock mode — simula ad completado instantaneamente no desktop
var mock_mode := true

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

func show_rewarded_ad(callback: Callable) -> void:
	if mock_mode:
		# Simula ad completado
		callback.call()
		return
	# TODO: integrar GodotAdMob aqui
	# AdMob.show_rewarded_ad()
	# conectar sinal de ad_completed ao callback
	callback.call()

class_name TrSystem
extends Node

var locale := "en"
signal locale_changed

const LOCALES := ["en", "pt", "es", "fr", "zh"]
const LOCALE_LABELS := ["EN", "PT", "ES", "FR", "中"]

const STRINGS := {
	# ===== TÍTULO =====
	"PLAY": { "pt": "JOGAR", "en": "PLAY", "es": "JUGAR", "fr": "JOUER", "zh": "开始" },
	"RESET_SAVE": { "pt": "APAGAR DADOS", "en": "RESET DATA", "es": "BORRAR DATOS", "fr": "EFFACER", "zh": "删除数据" },
	"QUIT": { "pt": "SAIR", "en": "QUIT", "es": "SALIR", "fr": "QUITTER", "zh": "退出" },
	"CONFIRM_DELETE": { "pt": "APAGAR DADOS?", "en": "DELETE DATA?", "es": "BORRAR DATOS?", "fr": "EFFACER DONNÉES?", "zh": "删除数据？" },
	"DELETE_WARNING": {
		"pt": "Todo progresso será perdido.\nEssa ação não pode ser desfeita.",
		"en": "All progress will be lost.\nThis cannot be undone.",
		"es": "Todo el progreso se perderá.\nEsta acción no se puede deshacer.",
		"fr": "Toute progression sera perdue.\nCette action est irréversible.",
		"zh": "所有进度将丢失。\n此操作无法撤销。",
	},
	"CANCEL": { "pt": "CANCELAR", "en": "CANCEL", "es": "CANCELAR", "fr": "ANNULER", "zh": "取消" },
	"DELETE": { "pt": "APAGAR", "en": "DELETE", "es": "BORRAR", "fr": "EFFACER", "zh": "删除" },

	# ===== HUD / POPUPS =====
	"PAUSED": { "pt": "PAUSADO", "en": "PAUSED", "es": "PAUSA", "fr": "PAUSE", "zh": "暂停" },
	"MUSIC": { "pt": "MÚSICA", "en": "MUSIC", "es": "MÚSICA", "fr": "MUSIQUE", "zh": "音乐" },
	"SFX": { "pt": "EFEITOS", "en": "SFX", "es": "EFECTOS", "fr": "EFFETS", "zh": "音效" },
	"SCANLINES": { "pt": "SCANLINES", "en": "SCANLINES", "es": "SCANLINES", "fr": "SCANLINES", "zh": "扫描线" },
	"RESUME": { "pt": "CONTINUAR", "en": "RESUME", "es": "CONTINUAR", "fr": "REPRENDRE", "zh": "继续" },
	"MAIN_MENU": { "pt": "MENU INICIAL", "en": "MAIN MENU", "es": "MENÚ PRINCIPAL", "fr": "MENU PRINCIPAL", "zh": "主菜单" },
	"GIVE_UP": { "pt": "DESISTIR", "en": "GIVE UP", "es": "RENDIRSE", "fr": "ABANDONNER", "zh": "放弃" },
	"GAME_OVER": { "pt": "GAME OVER", "en": "GAME OVER", "es": "FIN DEL JUEGO", "fr": "FIN DE PARTIE", "zh": "游戏结束" },
	"VICTORY": { "pt": "VITÓRIA!", "en": "VICTORY!", "es": "¡VICTORIA!", "fr": "VICTOIRE!", "zh": "胜利！" },
	"RUN_EARNINGS": { "pt": "GANHOS DA RUN", "en": "RUN EARNINGS", "es": "GANANCIAS", "fr": "GAINS DE LA RUN", "zh": "本轮收入" },
	"NO_EARNINGS": { "pt": "Nenhum ganho", "en": "No earnings", "es": "Sin ganancias", "fr": "Aucun gain", "zh": "无收入" },
	"CONTINUE": { "pt": "CONTINUAR", "en": "CONTINUE", "es": "CONTINUAR", "fr": "CONTINUER", "zh": "继续" },
	"REVIVE_TITLE": { "pt": "REVIVER?", "en": "REVIVE?", "es": "¿REVIVIR?", "fr": "REVIVRE?", "zh": "复活？" },
	"REVIVE_SUBTITLE": {
		"pt": "Assista um anúncio para reviver",
		"en": "Watch an ad to revive",
		"es": "Mira un anuncio para revivir",
		"fr": "Regardez une pub pour revivre",
		"zh": "观看广告复活",
	},
	"REVIVE": { "pt": "REVIVER", "en": "REVIVE", "es": "REVIVIR", "fr": "REVIVRE", "zh": "复活" },
	"NO": { "pt": "NÃO", "en": "NO", "es": "NO", "fr": "NON", "zh": "不" },
	"DOUBLE_TITLE": { "pt": "DOBRAR GANHOS?", "en": "DOUBLE EARNINGS?", "es": "¿DOBLAR GANANCIAS?", "fr": "DOUBLER LES GAINS?", "zh": "双倍收入？" },
	"DOUBLE_SUBTITLE": {
		"pt": "Assista um anúncio para dobrar",
		"en": "Watch an ad to double",
		"es": "Mira un anuncio para doblar",
		"fr": "Regardez une pub pour doubler",
		"zh": "观看广告翻倍",
	},
	"DOUBLE_BTN": { "pt": "DOBRAR (AD)", "en": "DOUBLE (AD)", "es": "DOBLAR (AD)", "fr": "DOUBLER (PUB)", "zh": "翻倍(广告)" },
	"DOUBLE_EARNINGS_AD": { "pt": "DOBRAR GANHOS (AD)", "en": "DOUBLE EARNINGS (AD)", "es": "DOBLAR GANANCIAS (AD)", "fr": "DOUBLER GAINS (PUB)", "zh": "双倍收入(广告)" },
	"AD_UNAVAILABLE": { "pt": "ANÚNCIO INDISPONÍVEL", "en": "AD UNAVAILABLE", "es": "ANUNCIO NO DISPONIBLE", "fr": "PUB INDISPONIBLE", "zh": "广告不可用" },
	"THREAT_FMT": { "pt": "AMEAÇA: %d", "en": "THREAT: %d", "es": "AMENAZA: %d", "fr": "MENACE: %d", "zh": "威胁：%d" },
	"EMPTY": { "pt": "VAZIO", "en": "EMPTY", "es": "VACÍO", "fr": "VIDE", "zh": "空" },
	"NO_AMMO": { "pt": "SEM MUNIÇÃO!", "en": "NO AMMO!", "es": "¡SIN MUNICIÓN!", "fr": "PAS DE MUNITIONS!", "zh": "没有弹药！" },

	# ===== ARSENAL =====
	"SHOP_TITLE": { "pt": "ARSENAL", "en": "ARSENAL", "es": "ARSENAL", "fr": "ARSENAL", "zh": "军火库" },
	"ETER_SHOP_TITLE": { "pt": "UPGRADES ETERNOS", "en": "ETERNAL UPGRADES", "es": "MEJORAS ETERNAS", "fr": "AMÉLIORATIONS ÉTERNELLES", "zh": "永恒升级" },
	"ASCEND": { "pt": "ASCENDER", "en": "ASCEND", "es": "ASCENDER", "fr": "ASCENSION", "zh": "飞升" },
	"MAX": { "pt": "MAX", "en": "MAX", "es": "MÁX", "fr": "MAX", "zh": "满级" },
	"COMPLETE": { "pt": "COMPLETO", "en": "COMPLETE", "es": "COMPLETO", "fr": "COMPLET", "zh": "已满" },
	"TAP_TO_BUY": { "pt": "— toque para comprar", "en": "— tap to buy", "es": "— toca para comprar", "fr": "— appuyez pour acheter", "zh": "— 点击购买" },
	"LV_FMT": { "pt": "Lv %d/%d", "en": "Lv %d/%d", "es": "Nv %d/%d", "fr": "Nv %d/%d", "zh": "等级 %d/%d" },
	"COST_FMT": { "pt": "Custo: %d", "en": "Cost: %d", "es": "Costo: %d", "fr": "Coût: %d", "zh": "费用：%d" },
	"REQUIRES_FMT": { "pt": "Requer: %s", "en": "Requires: %s", "es": "Requiere: %s", "fr": "Requiert: %s", "zh": "需要：%s" },

	# ===== ASCENSÃO =====
	"ASC_TITLE": { "pt": "ASCENSÃO", "en": "ASCENSION", "es": "ASCENSIÓN", "fr": "ASCENSION", "zh": "飞升" },
	"WARNING_TITLE": { "pt": "AVISO", "en": "WARNING", "es": "AVISO", "fr": "ATTENTION", "zh": "警告" },
	"WARNING_TEXT": {
		"pt": "Upgrades serão perdidos\nMoedas serão zeradas",
		"en": "Upgrades will be lost\nCurrencies will be reset",
		"es": "Las mejoras se perderán\nLas monedas se reiniciarán",
		"fr": "Les améliorations seront perdues\nLes monnaies seront réinitialisées",
		"zh": "升级将丢失\n货币将重置",
	},
	"BACK": { "pt": "VOLTAR", "en": "BACK", "es": "VOLVER", "fr": "RETOUR", "zh": "返回" },
	"ASC_CONFIRM": { "pt": "ASCENDER", "en": "ASCEND", "es": "ASCENDER", "fr": "ASCENSION", "zh": "飞升" },
	"ETER_GAINED": { "pt": "ÉTER GANHO", "en": "ETHER GAINED", "es": "ÉTER GANADO", "fr": "ÉTHER GAGNÉ", "zh": "获得以太" },
	"ETER_TOTAL_FMT": { "pt": "ÉTER TOTAL: %d → %d", "en": "TOTAL ETHER: %d → %d", "es": "ÉTER TOTAL: %d → %d", "fr": "ÉTHER TOTAL: %d → %d", "zh": "以太总量：%d → %d" },
	"INVESTED_FMT": { "pt": "INVESTIDO: %d / %d", "en": "INVESTED: %d / %d", "es": "INVERTIDO: %d / %d", "fr": "INVESTI: %d / %d", "zh": "已投资：%d / %d" },
	"ASC_COUNT_FMT": { "pt": "ASCENSÕES: %d", "en": "ASCENSIONS: %d", "es": "ASCENSIONES: %d", "fr": "ASCENSIONS: %d", "zh": "飞升次数：%d" },

	# ===== NOMES DE UPGRADE =====
	"UPG_NAME_extra_city": { "pt": "EXTRA CITY", "en": "EXTRA CITY", "es": "CIUDAD EXTRA", "fr": "CITÉ BONUS", "zh": "额外城市" },
	"UPG_NAME_ammo_pack": { "pt": "AMMO PACK", "en": "AMMO PACK", "es": "PACK MUNICIÓN", "fr": "PACK MUNITIONS", "zh": "弹药包" },
	"UPG_NAME_magazine": { "pt": "MAGAZINE+", "en": "MAGAZINE+", "es": "CARGADOR+", "fr": "CHARGEUR+", "zh": "弹匣+" },
	"UPG_NAME_ammo_regen": { "pt": "AMMO REGEN", "en": "AMMO REGEN", "es": "REGEN MUNICIÓN", "fr": "REGEN MUNITIONS", "zh": "弹药再生" },
	"UPG_NAME_hyper_drive": { "pt": "HYPER DRIVE", "en": "HYPER DRIVE", "es": "HIPERVELOCIDAD", "fr": "HYPERDRIVE", "zh": "超级驱动" },
	"UPG_NAME_warhead": { "pt": "WARHEAD+", "en": "WARHEAD+", "es": "OJIVA+", "fr": "OGIVE+", "zh": "弹头+" },
	"UPG_NAME_head_start": { "pt": "HEAD START", "en": "HEAD START", "es": "VENTAJA INICIAL", "fr": "AVANCE", "zh": "先发制人" },
	"UPG_NAME_credit_boost": { "pt": "CREDIT BOOST", "en": "CREDIT BOOST", "es": "MÁS CRÉDITOS", "fr": "BONUS CRÉDITS", "zh": "信用加成" },
	"UPG_NAME_time_warp": { "pt": "TIME WARP", "en": "TIME WARP", "es": "DISTORSIÓN", "fr": "DISTORSION", "zh": "时间扭曲" },
	"UPG_NAME_early_warning": { "pt": "EARLY WARNING", "en": "EARLY WARNING", "es": "ALERTA TEMPRANA", "fr": "ALERTE PRÉCOCE", "zh": "预警系统" },
	"UPG_NAME_extra_battery": { "pt": "EXTRA BATTERY", "en": "EXTRA BATTERY", "es": "BATERÍA EXTRA", "fr": "BATTERIE BONUS", "zh": "额外炮台" },
	"UPG_NAME_city_shield": { "pt": "CITY SHIELD", "en": "CITY SHIELD", "es": "ESCUDO URBANO", "fr": "BOUCLIER CITÉ", "zh": "城市护盾" },
	"UPG_NAME_warp_reload": { "pt": "WARP RELOAD", "en": "WARP RELOAD", "es": "RECARGA WARP", "fr": "RECHARGE WARP", "zh": "曲速装填" },
	"UPG_NAME_overcharge": { "pt": "OVERCHARGE", "en": "OVERCHARGE", "es": "SOBRECARGA", "fr": "SURCHARGE", "zh": "过载充能" },
	"UPG_NAME_critical_mass": { "pt": "CRITICAL MASS", "en": "CRITICAL MASS", "es": "MASA CRÍTICA", "fr": "MASSE CRITIQUE", "zh": "临界质量" },
	"UPG_NAME_crystal_boost": { "pt": "CRYSTAL BOOST", "en": "CRYSTAL BOOST", "es": "MÁS CRISTALES", "fr": "BONUS CRISTAUX", "zh": "水晶加成" },
	"UPG_NAME_homing": { "pt": "HOMING", "en": "HOMING", "es": "RASTREO", "fr": "AUTOGUIDÉ", "zh": "追踪导弹" },
	"UPG_NAME_triple_burst": { "pt": "TRIPLE BURST", "en": "TRIPLE BURST", "es": "TRIPLE RÁFAGA", "fr": "TRIPLE TIR", "zh": "三连发" },
	"UPG_NAME_temporal_freeze": { "pt": "TEMPORAL FREEZE", "en": "TEMPORAL FREEZE", "es": "CONGELACIÓN", "fr": "GEL TEMPOREL", "zh": "时间冻结" },
	"UPG_NAME_phoenix_protocol": { "pt": "PHOENIX PROTOCOL", "en": "PHOENIX PROTOCOL", "es": "PROTOCOLO FÉNIX", "fr": "PROTOCOLE PHÉNIX", "zh": "凤凰协议" },
	"UPG_NAME_singularity": { "pt": "SINGULARITY", "en": "SINGULARITY", "es": "SINGULARIDAD", "fr": "SINGULARITÉ", "zh": "奇点" },
	"UPG_NAME_auto_turret": { "pt": "AUTO TURRET", "en": "AUTO TURRET", "es": "TORRETA AUTO", "fr": "TOURELLE AUTO", "zh": "自动炮塔" },
	"UPG_NAME_mirror_array": { "pt": "MIRROR ARRAY", "en": "MIRROR ARRAY", "es": "RED DE ESPEJOS", "fr": "RÉSEAU MIROIR", "zh": "镜面阵列" },
	"UPG_NAME_void_boost": { "pt": "VOID BOOST", "en": "VOID BOOST", "es": "MÁS VACÍO", "fr": "BONUS VIDE", "zh": "虚空加成" },
	"UPG_NAME_ascendant_core": { "pt": "ASCENDANT CORE", "en": "ASCENDANT CORE", "es": "NÚCLEO ASCENDENTE", "fr": "NOYAU ASCENDANT", "zh": "超越核心" },
	"UPG_NAME_eternal_knowledge": { "pt": "ETERNAL KNOWLEDGE", "en": "ETERNAL KNOWLEDGE", "es": "SABER ETERNO", "fr": "SAVOIR ÉTERNEL", "zh": "永恒知识" },
	"UPG_NAME_vault": { "pt": "VAULT", "en": "VAULT", "es": "BÓVEDA", "fr": "COFFRE", "zh": "保险库" },
	"UPG_NAME_omega_protocol": { "pt": "OMEGA PROTOCOL", "en": "OMEGA PROTOCOL", "es": "PROTOCOLO OMEGA", "fr": "PROTOCOLE OMÉGA", "zh": "终极协议" },

	# ===== DESCRIÇÕES DE UPGRADE =====
	"UPG_DESC_extra_city": { "pt": "+1 cidade/nível", "en": "+1 city/level", "es": "+1 ciudad/nivel", "fr": "+1 cité/niveau", "zh": "+1城市/级" },
	"UPG_DESC_ammo_pack": { "pt": "+1 pente/bateria/nível", "en": "+1 mag/battery/level", "es": "+1 cargador/batería/nivel", "fr": "+1 chargeur/batterie/niveau", "zh": "+1弹匣/炮台/级" },
	"UPG_DESC_magazine": { "pt": "+1 tiro/pente/nível", "en": "+1 shot/mag/level", "es": "+1 tiro/cargador/nivel", "fr": "+1 tir/chargeur/niveau", "zh": "+1发/弹匣/级" },
	"UPG_DESC_ammo_regen": { "pt": "+0.1 pentes/s/nível", "en": "+0.1 mags/s/level", "es": "+0.1 cargadores/s/nivel", "fr": "+0.1 chargeurs/s/niveau", "zh": "+0.1弹匣/秒/级" },
	"UPG_DESC_hyper_drive": { "pt": "+40% velocidade/nível", "en": "+40% speed/level", "es": "+40% velocidad/nivel", "fr": "+40% vitesse/niveau", "zh": "+40%速度/级" },
	"UPG_DESC_warhead": { "pt": "+40% raio de explosão/nível", "en": "+40% blast radius/level", "es": "+40% radio explosión/nivel", "fr": "+40% rayon explosion/niveau", "zh": "+40%爆炸半径/级" },
	"UPG_DESC_head_start": { "pt": "+20 créditos iniciais/nível", "en": "+20 starting credits/level", "es": "+20 créditos iniciales/nivel", "fr": "+20 crédits de départ/niveau", "zh": "+20初始信用/级" },
	"UPG_DESC_credit_boost": { "pt": "+1 crédito/abate/nível", "en": "+1 credit/kill/level", "es": "+1 crédito/baja/nivel", "fr": "+1 crédit/élimination/niveau", "zh": "+1信用/击杀/级" },
	"UPG_DESC_time_warp": { "pt": "+8% chance de slow/nível", "en": "+8% slow chance/level", "es": "+8% prob. ralentizar/nivel", "fr": "+8% chance ralentir/niveau", "zh": "+8%减速几率/级" },
	"UPG_DESC_early_warning": { "pt": "Alerta de impacto", "en": "Impact alert", "es": "Alerta de impacto", "fr": "Alerte d'impact", "zh": "撞击预警" },
	"UPG_DESC_extra_battery": { "pt": "+1 bateria/nível", "en": "+1 battery/level", "es": "+1 batería/nivel", "fr": "+1 batterie/niveau", "zh": "+1炮台/级" },
	"UPG_DESC_city_shield": { "pt": "+1 escudo/cidade/nível", "en": "+1 shield/city/level", "es": "+1 escudo/ciudad/nivel", "fr": "+1 bouclier/cité/niveau", "zh": "+1护盾/城市/级" },
	"UPG_DESC_warp_reload": { "pt": "-12% recarga/nível", "en": "-12% reload/level", "es": "-12% recarga/nivel", "fr": "-12% recharge/niveau", "zh": "-12%装填时间/级" },
	"UPG_DESC_overcharge": { "pt": "+15% velocidade de carga/nível", "en": "+15% charge speed/level", "es": "+15% velocidad carga/nivel", "fr": "+15% vitesse charge/niveau", "zh": "+15%充能速度/级" },
	"UPG_DESC_critical_mass": { "pt": "+4% chance de crítico/nível", "en": "+4% crit chance/level", "es": "+4% prob. crítico/nivel", "fr": "+4% chance critique/niveau", "zh": "+4%暴击几率/级" },
	"UPG_DESC_crystal_boost": { "pt": "+1 cristal/abate/nível", "en": "+1 crystal/kill/level", "es": "+1 cristal/baja/nivel", "fr": "+1 cristal/élimination/niveau", "zh": "+1水晶/击杀/级" },
	"UPG_DESC_homing": { "pt": "+15% chance de guiar/nível", "en": "+15% homing chance/level", "es": "+15% prob. rastreo/nivel", "fr": "+15% chance autoguidage/niveau", "zh": "+15%追踪几率/级" },
	"UPG_DESC_triple_burst": { "pt": "+8% chance de tiro triplo/nível", "en": "+8% triple shot chance/level", "es": "+8% prob. triple/nivel", "fr": "+8% chance triple tir/niveau", "zh": "+8%三连发几率/级" },
	"UPG_DESC_temporal_freeze": { "pt": "+1.5s de freeze/nível", "en": "+1.5s freeze/level", "es": "+1.5s congelación/nivel", "fr": "+1.5s gel/niveau", "zh": "+1.5秒冻结/级" },
	"UPG_DESC_phoenix_protocol": { "pt": "+1 revive de cidade/nível", "en": "+1 city revive/level", "es": "+1 revivir ciudad/nivel", "fr": "+1 résurrection cité/niveau", "zh": "+1城市复活/级" },
	"UPG_DESC_singularity": { "pt": "Puxa inimigos nas explosões", "en": "Explosions pull enemies", "es": "Explosiones atraen enemigos", "fr": "Les explosions attirent les ennemis", "zh": "爆炸吸引敌人" },
	"UPG_DESC_auto_turret": { "pt": "+1 torreta automática/nível", "en": "+1 auto turret/level", "es": "+1 torreta auto/nivel", "fr": "+1 tourelle auto/niveau", "zh": "+1自动炮塔/级" },
	"UPG_DESC_mirror_array": { "pt": "+5% chance de refletir/nível", "en": "+5% reflect chance/level", "es": "+5% prob. reflejar/nivel", "fr": "+5% chance reflet/niveau", "zh": "+5%反射几率/级" },
	"UPG_DESC_void_boost": { "pt": "+1 void/abate/nível", "en": "+1 void/kill/level", "es": "+1 vacío/baja/nivel", "fr": "+1 vide/élimination/niveau", "zh": "+1虚空/击杀/级" },
	"UPG_DESC_ascendant_core": { "pt": "x2 → x4 ganho de moedas", "en": "x2 → x4 currency gain", "es": "x2 → x4 ganancia monedas", "fr": "x2 → x4 gain monnaies", "zh": "x2 → x4 货币收益" },
	"UPG_DESC_eternal_knowledge": { "pt": "Mantém upgrades ao ascender", "en": "Keep upgrades on ascension", "es": "Conserva mejoras al ascender", "fr": "Garde les améliorations à l'ascension", "zh": "飞升保留升级" },
	"UPG_DESC_vault": { "pt": "Mantém moedas ao ascender", "en": "Keep currencies on ascension", "es": "Conserva monedas al ascender", "fr": "Garde les monnaies à l'ascension", "zh": "飞升保留货币" },
	"UPG_DESC_omega_protocol": { "pt": "+50% drops, 3x dificuldade, 2 bosses", "en": "+50% drops, 3x difficulty, 2 bosses", "es": "+50% drops, 3x dificultad, 2 jefes", "fr": "+50% drops, 3x difficulté, 2 boss", "zh": "+50%掉落，3倍难度，2个Boss" },
}

func t(key: String) -> String:
	if not STRINGS.has(key):
		return key
	var entry: Dictionary = STRINGS[key]
	if entry.has(locale):
		return entry[locale]
	if entry.has("en"):
		return entry["en"]
	return key

func set_locale(loc: String) -> void:
	if loc in LOCALES:
		locale = loc
		locale_changed.emit()

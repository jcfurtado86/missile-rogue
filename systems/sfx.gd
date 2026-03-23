extends Node

# Pool de AudioStreamPlayers para tocar sons simultaneos
const POOL_SIZE := 12
var players: Array[AudioStreamPlayer] = []
var next_player := 0

# Streams pre-gerados
var stream_fire: AudioStreamWAV
var stream_explosion: AudioStreamWAV
var stream_ground_hit: AudioStreamWAV
var stream_city_nuked: AudioStreamWAV
var stream_intercept: AudioStreamWAV
var stream_nova_bomb: AudioStreamWAV
var stream_ui_click: AudioStreamWAV
var stream_purchase: AudioStreamWAV

func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		players.append(p)
	get_tree().node_added.connect(_on_node_added)
	stream_fire = _gen_fire()
	stream_explosion = _gen_explosion()
	stream_ground_hit = _gen_ground_hit()
	stream_city_nuked = _gen_city_nuked()
	stream_intercept = _gen_intercept()
	stream_nova_bomb = _gen_nova_bomb()
	stream_ui_click = _gen_ui_click()
	stream_purchase = _gen_purchase()

func _play(stream: AudioStreamWAV, volume_db := 0.0, pitch := 1.0) -> void:
	var p := players[next_player]
	next_player = (next_player + 1) % POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()

func fire(pitch_variation := 0.15) -> void:
	_play(stream_fire, -6.0, randf_range(1.0 - pitch_variation, 1.0 + pitch_variation))

func explosion(pitch_variation := 0.2) -> void:
	_play(stream_explosion, -8.0, randf_range(1.0 - pitch_variation, 1.0 + pitch_variation))

func ground_hit() -> void:
	_play(stream_ground_hit, -5.0, randf_range(0.9, 1.1))

func city_nuked() -> void:
	_play(stream_city_nuked, -2.0, randf_range(0.9, 1.05))

func nova_bomb() -> void:
	_play(stream_nova_bomb, -3.0, 1.0)

func ui_click() -> void:
	_play(stream_ui_click, -10.0, randf_range(0.95, 1.05))

func purchase() -> void:
	_play(stream_purchase, -6.0, randf_range(0.95, 1.05))

func _on_node_added(node: Node) -> void:
	if node is Button and not node.has_meta("no_click_sfx"):
		node.ready.connect(func():
			if not node.has_meta("no_click_sfx"):
				node.pressed.connect(ui_click)
		)

func intercept(pitch_variation := 0.15) -> void:
	_play(stream_intercept, -7.0, randf_range(1.0 - pitch_variation, 1.0 + pitch_variation))

# --- Geracao procedural ---

func _gen_fire() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.18
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var t := float(i) / sample_rate
		var env := clampf(1.0 - t / duration, 0.0, 1.0)
		env *= env
		var freq := lerpf(800.0, 200.0, t / duration)
		var osc := sin(TAU * freq * t) * 0.5
		var noise := (randf() * 2.0 - 1.0) * 0.3
		var attack := clampf(1.0 - t / 0.02, 0.0, 1.0)
		var click := sin(TAU * 2200.0 * t) * attack * 0.4
		var sample := (osc + noise + click) * env
		var s16 := clampi(int(sample * 32000.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _gen_explosion() -> AudioStreamWAV:
	# Explosao: ruido com envelope de impacto + tom grave
	var sample_rate := 22050
	var duration := 0.35
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var t := float(i) / sample_rate
		# Envelope: pico rapido + decay lento
		var env := clampf(1.0 - t / duration, 0.0, 1.0)
		env = pow(env, 1.5)
		# Impacto inicial forte
		var impact := clampf(1.0 - t / 0.03, 0.0, 1.0) * 0.5
		# Tom grave descendente (150Hz -> 40Hz)
		var freq := lerpf(150.0, 40.0, t / duration)
		var bass := sin(TAU * freq * t) * 0.4
		# Ruido de explosao
		var noise := (randf() * 2.0 - 1.0) * 0.5
		# Crackle medio (ruido filtrado)
		var crackle := sin(TAU * 300.0 * t + sin(TAU * 50.0 * t) * 8.0) * 0.2
		var sample := (bass + noise + crackle + impact) * env
		var s16 := clampi(int(sample * 30000.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _gen_ground_hit() -> AudioStreamWAV:
	# Impacto no solo: explosao media
	var sample_rate := 22050
	var duration := 0.4
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var t := float(i) / sample_rate
		var env := clampf(1.0 - t / duration, 0.0, 1.0)
		env = pow(env, 1.3)
		var impact := clampf(1.0 - t / 0.03, 0.0, 1.0) * 0.6
		var sub := sin(TAU * lerpf(100.0, 35.0, t / duration) * t) * 0.4
		var noise := (randf() * 2.0 - 1.0) * 0.35
		var crackle := sin(TAU * 350.0 * t + sin(TAU * 60.0 * t) * 5.0) * 0.15 * clampf(1.0 - t / 0.2, 0.0, 1.0)
		var sample := (sub + noise + crackle + impact) * env
		var s16 := clampi(int(sample * 28000.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _gen_city_nuked() -> AudioStreamWAV:
	# Cidade destruida: explosao nuclear massiva, longa, devastadora
	var sample_rate := 22050
	var duration := 1.2
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var t := float(i) / sample_rate
		# Envelope longo com decay lento
		var env := clampf(1.0 - t / duration, 0.0, 1.0)
		env = pow(env, 0.8)
		# Impacto massivo duplo
		var impact := clampf(1.0 - t / 0.04, 0.0, 1.0) * 0.8
		var impact2 := clampf(1.0 - abs(t - 0.08) / 0.04, 0.0, 1.0) * 0.5
		# Sub-bass profundo (60Hz -> 18Hz)
		var sub := sin(TAU * lerpf(60.0, 18.0, t / duration) * t) * 0.6
		# Ruido denso e pesado
		var noise := (randf() * 2.0 - 1.0) * 0.5
		# Onda de choque (sweep descendente rapido)
		var shockwave := sin(TAU * lerpf(500.0, 30.0, clampf(t / 0.15, 0.0, 1.0)) * t) * 0.4 * clampf(1.0 - t / 0.2, 0.0, 1.0)
		# Ressonancia de destrocos (FM)
		var debris := sin(TAU * 200.0 * t + sin(TAU * 40.0 * t) * 10.0) * 0.2 * clampf(1.0 - t / 0.6, 0.0, 1.0)
		# Rumble prolongado
		var rumble := sin(TAU * lerpf(30.0, 15.0, t / duration) * t) * 0.3 * clampf(t / 0.1, 0.0, 1.0)
		var sample := (sub + noise + shockwave + debris + rumble + impact + impact2) * env
		var s16 := clampi(int(sample * 24000.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _gen_intercept() -> AudioStreamWAV:
	# Interceptacao: impacto explosivo + sweep ascendente satisfatorio
	var sample_rate := 22050
	var duration := 0.32
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var t := float(i) / sample_rate
		var env := clampf(1.0 - t / duration, 0.0, 1.0)
		env = pow(env, 1.3)
		# Impacto forte no inicio
		var impact := clampf(1.0 - t / 0.025, 0.0, 1.0) * 0.7
		# Bass punch (120Hz -> 50Hz)
		var bass := sin(TAU * lerpf(120.0, 50.0, t / duration) * t) * 0.35
		# Sweep ascendente (250Hz -> 900Hz) — sensacao positiva
		var freq := lerpf(250.0, 900.0, t / duration)
		var tone := sin(TAU * freq * t) * 0.3
		# Harmonico brilhante
		var bright := sin(TAU * freq * 2.5 * t) * 0.15 * clampf(1.0 - t / 0.15, 0.0, 1.0)
		# Ruido explosivo
		var noise := (randf() * 2.0 - 1.0) * 0.35
		# Crackle de destrocos
		var crackle := sin(TAU * 450.0 * t + sin(TAU * 80.0 * t) * 6.0) * 0.15 * clampf(1.0 - t / 0.2, 0.0, 1.0)
		var sample := (bass + tone + bright + noise + crackle + impact) * env
		var s16 := clampi(int(sample * 28000.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _gen_nova_bomb() -> AudioStreamWAV:
	# Nova bomb: onda de energia expandindo — sweep ascendente + pulso massivo
	var sample_rate := 22050
	var duration := 0.9
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var t := float(i) / sample_rate
		var env := clampf(1.0 - t / duration, 0.0, 1.0)
		env = pow(env, 0.6)
		# Charge-up sweep ascendente (100Hz -> 2000Hz)
		var sweep_t := clampf(t / 0.3, 0.0, 1.0)
		var freq := lerpf(100.0, 2000.0, sweep_t * sweep_t)
		var sweep := sin(TAU * freq * t) * 0.4 * clampf(1.0 - t / 0.4, 0.0, 1.0)
		# Pulso de energia no pico (~0.15s)
		var pulse_env := clampf(1.0 - abs(t - 0.15) / 0.08, 0.0, 1.0)
		var pulse := sin(TAU * 800.0 * t) * pulse_env * 0.5
		# Onda expandindo (tom medio descendente)
		var wave_t := clampf((t - 0.1) / 0.8, 0.0, 1.0)
		var wave := sin(TAU * lerpf(600.0, 80.0, wave_t) * t) * 0.35 * clampf((t - 0.1) / 0.05, 0.0, 1.0)
		# Ruido de energia
		var noise := (randf() * 2.0 - 1.0) * 0.25 * env
		# Sub-bass de impacto
		var sub := sin(TAU * 40.0 * t) * 0.3 * clampf((t - 0.1) / 0.05, 0.0, 1.0)
		var sample := (sweep + pulse + wave + noise + sub) * env
		var s16 := clampi(int(sample * 26000.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _gen_ui_click() -> AudioStreamWAV:
	# Click de UI: blip curto e limpo
	var sample_rate := 22050
	var duration := 0.06
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var t := float(i) / sample_rate
		var env := clampf(1.0 - t / duration, 0.0, 1.0)
		env = pow(env, 2.0)
		# Tom agudo limpo
		var tone := sin(TAU * 1400.0 * t) * 0.4
		# Harmonico
		var harm := sin(TAU * 2800.0 * t) * 0.15 * clampf(1.0 - t / 0.02, 0.0, 1.0)
		var sample := (tone + harm) * env
		var s16 := clampi(int(sample * 30000.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _gen_purchase() -> AudioStreamWAV:
	# Compra: dois tons ascendentes rapidos (ka-ching sintetico)
	var sample_rate := 22050
	var duration := 0.25
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var t := float(i) / sample_rate
		var env := clampf(1.0 - t / duration, 0.0, 1.0)
		env = pow(env, 1.5)
		# Primeiro tom (0-0.08s)
		var t1_env := clampf(1.0 - abs(t - 0.03) / 0.05, 0.0, 1.0)
		var tone1 := sin(TAU * 1000.0 * t) * t1_env * 0.4
		# Segundo tom mais agudo (0.06-0.18s)
		var t2_env := clampf(1.0 - abs(t - 0.11) / 0.07, 0.0, 1.0)
		var tone2 := sin(TAU * 1500.0 * t) * t2_env * 0.4
		# Brilho
		var shimmer := sin(TAU * 3000.0 * t) * 0.1 * env
		var sample := (tone1 + tone2 + shimmer) * env
		var s16 := clampi(int(sample * 30000.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

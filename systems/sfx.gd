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
var stream_boss_spawn: AudioStreamWAV
var stream_boss_defeated: AudioStreamWAV

# Referencia da musica para controle de pitch
var music_player: AudioStreamPlayer = null
var music_target_pitch := 1.0
var music_current_pitch := 1.0

var music_volume_db := 0.0
var sfx_volume_db := 0.0

func _ready() -> void:
	# Cria buses de audio separados
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
		AudioServer.set_bus_send(AudioServer.get_bus_index("Music"), "Master")
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
		AudioServer.set_bus_send(AudioServer.get_bus_index("SFX"), "Master")
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
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
	stream_boss_spawn = _gen_boss_spawn()
	stream_boss_defeated = _gen_boss_defeated()
	_start_music()

func _start_music() -> void:
	var ogg_stream = load("res://assets/audio/neon.ogg")
	if ogg_stream:
		ogg_stream.loop = true
		music_player = AudioStreamPlayer.new()
		music_player.stream = ogg_stream
		music_player.bus = "Music"
		add_child(music_player)
		music_player.play()

func _process(delta: float) -> void:
	if music_player and abs(music_current_pitch - music_target_pitch) > 0.01:
		music_current_pitch = lerpf(music_current_pitch, music_target_pitch, delta * 2.0)
		music_player.pitch_scale = music_current_pitch

func set_music_pitch(pitch: float) -> void:
	music_target_pitch = pitch

func reset_music_pitch() -> void:
	music_target_pitch = 1.0

func set_music_volume(linear: float) -> void:
	music_volume_db = linear_to_db(clampf(linear, 0.001, 1.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music_volume_db)

func set_sfx_volume(linear: float) -> void:
	sfx_volume_db = linear_to_db(clampf(linear, 0.001, 1.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfx_volume_db)

func get_music_volume_linear() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))

func get_sfx_volume_linear() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))

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

func boss_spawn() -> void:
	_play(stream_boss_spawn, -2.0, 1.0)

func boss_defeated() -> void:
	_play(stream_boss_defeated, 0.0, 1.0)

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

func _gen_boss_spawn() -> AudioStreamWAV:
	# Boss spawn: sirene ominosa + rumble grave crescente
	var sample_rate := 22050
	var duration := 1.5
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var t := float(i) / sample_rate
		# Envelope: cresce ate 0.8s, depois sustain
		var env := clampf(t / 0.8, 0.0, 1.0) * clampf(1.0 - (t - 1.2) / 0.3, 0.0, 1.0)
		# Sirene oscilatoria (frequencia modula entre 200-400Hz)
		var siren_freq := 300.0 + sin(TAU * 1.5 * t) * 100.0
		var siren := sin(TAU * siren_freq * t) * 0.3
		# Sub-bass crescente (30Hz -> 50Hz)
		var sub := sin(TAU * lerpf(30.0, 50.0, t / duration) * t) * 0.5
		# Rumble de maquinaria (FM grave)
		var rumble := sin(TAU * 45.0 * t + sin(TAU * 8.0 * t) * 6.0) * 0.3
		# Ruido metalico
		var noise := (randf() * 2.0 - 1.0) * 0.15 * clampf(t / 0.5, 0.0, 1.0)
		# Tom de alerta (pulsos a cada 0.3s)
		var alert_pulse := clampf(1.0 - fmod(t, 0.3) / 0.15, 0.0, 1.0)
		var alert := sin(TAU * 500.0 * t) * alert_pulse * 0.2
		var sample := (siren + sub + rumble + noise + alert) * env
		var s16 := clampi(int(sample * 22000.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _gen_boss_defeated() -> AudioStreamWAV:
	# Boss derrotado: explosao MASSIVA multi-camada, longa, triunfante
	var sample_rate := 22050
	var duration := 2.5
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var t := float(i) / sample_rate
		# Envelope longo com decay gradual
		var env := clampf(1.0 - t / duration, 0.0, 1.0)
		env = pow(env, 0.5)
		# Impacto triplo escalonado (0s, 0.1s, 0.25s)
		var impact1 := clampf(1.0 - t / 0.05, 0.0, 1.0) * 0.9
		var impact2 := clampf(1.0 - abs(t - 0.1) / 0.05, 0.0, 1.0) * 0.7
		var impact3 := clampf(1.0 - abs(t - 0.25) / 0.06, 0.0, 1.0) * 0.6
		# Sub-bass devastador (50Hz -> 12Hz)
		var sub := sin(TAU * lerpf(50.0, 12.0, t / duration) * t) * 0.7
		# Onda de choque massiva (1000Hz -> 20Hz em 0.3s)
		var shock_t := clampf(t / 0.3, 0.0, 1.0)
		var shockwave := sin(TAU * lerpf(1000.0, 20.0, shock_t * shock_t) * t) * 0.5 * clampf(1.0 - t / 0.4, 0.0, 1.0)
		# Ruido denso de explosao
		var noise := (randf() * 2.0 - 1.0) * 0.5
		# Destrocos e metal (FM caos)
		var debris := sin(TAU * 180.0 * t + sin(TAU * 35.0 * t) * 12.0) * 0.25 * clampf(1.0 - t / 1.0, 0.0, 1.0)
		# Rumble prolongado
		var rumble := sin(TAU * lerpf(25.0, 10.0, t / duration) * t) * 0.4 * clampf(t / 0.15, 0.0, 1.0)
		# Overtone triunfante (acorde maior ascendente depois de 0.5s)
		var triumph_env := clampf((t - 0.5) / 0.3, 0.0, 1.0) * clampf(1.0 - (t - 1.5) / 1.0, 0.0, 1.0)
		var triumph := (sin(TAU * 523.0 * t) * 0.15 + sin(TAU * 659.0 * t) * 0.1 + sin(TAU * 784.0 * t) * 0.08) * triumph_env
		# Segunda explosao tardia (eco)
		var echo_env := clampf(1.0 - abs(t - 0.8) / 0.15, 0.0, 1.0)
		var echo := (randf() * 2.0 - 1.0) * 0.3 * echo_env + sin(TAU * 60.0 * t) * 0.3 * echo_env
		var sample := (sub + shockwave + noise + debris + rumble + triumph + echo + impact1 + impact2 + impact3) * env
		var s16 := clampi(int(sample * 20000.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

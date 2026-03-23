extends Node

# Pool de AudioStreamPlayers para tocar sons simultaneos
const POOL_SIZE := 12
var players: Array[AudioStreamPlayer] = []
var next_player := 0

# Streams pre-gerados
var stream_fire: AudioStreamWAV
var stream_explosion: AudioStreamWAV
var stream_city_destroyed: AudioStreamWAV
var stream_intercept: AudioStreamWAV

func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		players.append(p)
	stream_fire = _gen_fire()
	stream_explosion = _gen_explosion()
	stream_city_destroyed = _gen_city_destroyed()
	stream_intercept = _gen_intercept()

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

func city_destroyed() -> void:
	_play(stream_city_destroyed, -4.0, randf_range(0.9, 1.1))

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

func _gen_city_destroyed() -> AudioStreamWAV:
	# Cidade destruida: explosao pesada + reverb sintetico + tom dramatico
	var sample_rate := 22050
	var duration := 0.7
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var t := float(i) / sample_rate
		# Envelope longo com decay
		var env := clampf(1.0 - t / duration, 0.0, 1.0)
		env = pow(env, 1.2)
		# Impacto massivo
		var impact := clampf(1.0 - t / 0.05, 0.0, 1.0) * 0.7
		# Sub-bass (80Hz -> 25Hz)
		var sub := sin(TAU * lerpf(80.0, 25.0, t / duration) * t) * 0.5
		# Ruido denso
		var noise := (randf() * 2.0 - 1.0) * 0.4
		# Tom dramatico descendente (400Hz -> 100Hz)
		var drama := sin(TAU * lerpf(400.0, 100.0, t / duration) * t) * 0.25 * clampf(1.0 - t / 0.4, 0.0, 1.0)
		# Ressonancia metalica
		var metal := sin(TAU * 600.0 * t) * sin(TAU * 3.0 * t) * 0.15 * clampf(1.0 - t / 0.3, 0.0, 1.0)
		var sample := (sub + noise + drama + metal + impact) * env
		var s16 := clampi(int(sample * 28000.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _gen_intercept() -> AudioStreamWAV:
	# Interceptacao: pop agudo + sweep ascendente (satisfatorio)
	var sample_rate := 22050
	var duration := 0.22
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var t := float(i) / sample_rate
		var env := clampf(1.0 - t / duration, 0.0, 1.0)
		env *= env
		# Pop inicial
		var pop := clampf(1.0 - t / 0.015, 0.0, 1.0) * 0.6
		# Sweep ascendente (300Hz -> 1200Hz) — sensacao positiva
		var freq := lerpf(300.0, 1200.0, t / duration)
		var tone := sin(TAU * freq * t) * 0.35
		# Harmonico brilhante
		var bright := sin(TAU * freq * 2.5 * t) * 0.15 * clampf(1.0 - t / 0.12, 0.0, 1.0)
		# Ruido leve
		var noise := (randf() * 2.0 - 1.0) * 0.15
		var sample := (tone + bright + noise + pop) * env
		var s16 := clampi(int(sample * 30000.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

extends SceneTree
## Builds the whole soundtrack and every sound effect from code, as small mono 22 kHz WAVs that Godot
## imports with QOA compression (see the .import files next to them). Nothing here ships in the game;
## rerun it after changing a track or a sound:
##   Godot --headless --path <project> --script res://tools/generate_audio.gd [-- name name ...]
## Passing names after "--" rebuilds only those tracks / sounds.
##
## Music is generated, not hand-written: each track picks a key, mode, tempo, chord progression and
## instruments, and a seeded melody writer fills the sections in (a motif, an answer, the motif again over
## new chords, and a cadence). Tracks loop seamlessly: echoes and note tails past the end wrap back to the
## start.

const RATE := 22050
const MUSIC_DIR := "res://audio/music/"
const SFX_DIR := "res://audio/sfx/"
const TAIL_SECONDS := 3.0
const BARS_PER_SECTION := 8

enum { PULSE, TRI, SAW, SINE, NOISE }

const SCALES := {
	"major": [0, 2, 4, 5, 7, 9, 11],
	"minor": [0, 2, 3, 5, 7, 8, 10],
	"dorian": [0, 2, 3, 5, 7, 9, 10],
	"harmonic": [0, 2, 3, 5, 7, 8, 11],
	"lydian": [0, 2, 4, 6, 7, 9, 11],
	"phrygian_dominant": [0, 1, 4, 5, 7, 8, 10],
}

## Lead rhythms: note lengths in 16ths that fill one bar.
const RHYTHMS := {
	"calm": [[8, 8], [4, 4, 8], [12, 4], [16], [6, 2, 8], [8, 4, 4]],
	"mid": [[4, 4, 4, 4], [6, 2, 4, 4], [4, 2, 2, 8], [8, 4, 4], [2, 2, 4, 4, 4], [4, 4, 8]],
	"fast": [[2, 2, 2, 2, 4, 4], [4, 2, 2, 4, 4], [2, 2, 4, 2, 2, 4], [3, 3, 2, 4, 4], [4, 4, 2, 2, 2, 2], [6, 2, 4, 4]],
}

var rng := RandomNumberGenerator.new()


func _init() -> void:
	var only := OS.get_cmdline_user_args()
	for dir in [MUSIC_DIR, SFX_DIR]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for spec: Dictionary in _tracks():
		if only.is_empty() or spec["name"] in only:
			var started := Time.get_ticks_msec()
			_save(MUSIC_DIR + spec["name"] + ".wav", _render_track(spec))
			print("music %s (%d ms)" % [spec["name"], Time.get_ticks_msec() - started])
	var sounds := _sounds()
	for sound_name: String in sounds:
		if only.is_empty() or sound_name in only:
			var sound: Array = sounds[sound_name]
			_save(SFX_DIR + sound_name + ".wav", _render_sfx(sound[0], sound[1]))
	print("sfx: %d sounds" % sounds.size())
	quit()


# --- Music ------------------------------------------------------------------------------------------


func _tracks() -> Array[Dictionary]:
	var no_drums := {}
	return [
		# Title: a wistful campfire tune, D dorian.
		{
			"name": "title", "bpm": 84, "root": 62, "scale": "dorian", "density": "calm", "rest": 0.12,
			"form": ["A", "B"],
			"prog": {"A": [0, 6, 2, 3, 0, 6, 3, 0], "B": [2, 6, 3, 0, 2, 6, 4, 4]},
			"lead": {"wave": TRI, "a": 0.03, "d": 0.4, "s": 0.7, "r": 0.2, "vib": 0.006, "detune": 0.003},
			"lead_vol": 0.34, "harmony": true,
			"bass": "half", "bass_inst": {"wave": TRI, "a": 0.02, "d": 0.5, "s": 0.6, "r": 0.15}, "bass_vol": 0.3,
			"arp": "broken8", "arp_inst": {"wave": PULSE, "duty": 0.25, "a": 0.005, "d": 0.25, "s": 0.0, "r": 0.05}, "arp_vol": 0.07,
			"drums": no_drums, "echo": [0.75, 0.38], "lowpass": 3600.0, "loudness": 0.15,
		},
		# Oblath: a bright pastoral village tune, G major.
		{
			"name": "oblath", "bpm": 112, "root": 67, "scale": "major", "density": "mid", "rest": 0.1,
			"form": ["A", "B", "A2", "B2"],
			"prog": {"A": [0, 3, 4, 0, 5, 3, 1, 4], "B": [3, 4, 2, 5, 3, 4, 0, 0]},
			"lead": {"wave": PULSE, "duty": 0.25, "a": 0.01, "d": 0.18, "s": 0.55, "r": 0.06, "vib": 0.007},
			"lead_vol": 0.27,
			"bass": "walk", "bass_inst": {"wave": TRI, "a": 0.005, "d": 0.2, "s": 0.5, "r": 0.04}, "bass_vol": 0.34,
			"arp": "arp16", "arp_inst": {"wave": PULSE, "duty": 0.125, "a": 0.002, "d": 0.08, "s": 0.0, "r": 0.02}, "arp_vol": 0.06,
			"drums": {"kick": "x.......x.......", "snare": "....g.......g...", "hat": "..x...x...x...x."},
			"drums2": {"kick": "x.......x.x.....", "snare": "....x.......x...", "hat": "x.x.x.x.x.x.x.x."},
			"echo": [0.75, 0.25], "lowpass": 5200.0, "loudness": 0.17,
		},
		# Saltwind Camp: a slow, swaying desert-caravan tune, E phrygian dominant over a drone.
		{
			"name": "saltwind", "bpm": 92, "root": 64, "scale": "phrygian_dominant", "density": "mid", "rest": 0.15,
			"form": ["A", "B"],
			"prog": {"A": [0, 0, 1, 0, 6, 6, 1, 0], "B": [3, 3, 1, 1, 6, 6, 1, 0]},
			"lead": {"wave": PULSE, "duty": 0.125, "a": 0.02, "d": 0.3, "s": 0.6, "r": 0.1, "vib": 0.012, "vib_rate": 6.5, "slide": 1.0},
			"lead_vol": 0.25,
			"bass": "drone", "bass_inst": {"wave": TRI, "a": 0.05, "d": 1.0, "s": 0.7, "r": 0.2}, "bass_vol": 0.3,
			"arp": "stab", "arp_inst": {"wave": PULSE, "duty": 0.25, "a": 0.003, "d": 0.08, "s": 0.0, "r": 0.03}, "arp_vol": 0.045,
			"drums": {"tom": "x..x..x...x.x...", "shaker": "..x...x...x...x.", "kick": "x.......x......."},
			"echo": [0.5, 0.3], "lowpass": 4200.0, "loudness": 0.15,
		},
		# Rimehollow: a music-box snowfall, A lydian, no drums.
		{
			"name": "rimehollow", "bpm": 78, "root": 69, "scale": "lydian", "density": "calm", "rest": 0.1,
			"form": ["A", "B"],
			"prog": {"A": [0, 1, 0, 1, 4, 1, 0, 0], "B": [5, 1, 4, 0, 5, 1, 4, 4]},
			"lead": {"wave": SINE, "a": 0.004, "d": 0.5, "s": 0.0, "r": 0.3, "detune": 0.004},
			"lead_vol": 0.42, "harmony": true,
			"bass": "half", "bass_inst": {"wave": SINE, "a": 0.05, "d": 0.8, "s": 0.6, "r": 0.3}, "bass_vol": 0.32,
			"arp": "bell", "arp_inst": {"wave": SINE, "a": 0.002, "d": 0.35, "s": 0.0, "r": 0.2}, "arp_vol": 0.13,
			"drums": no_drums, "echo": [0.75, 0.45], "lowpass": 5000.0, "loudness": 0.13,
		},
		# Ashgate Outpost: a tense military march under siege, C harmonic minor.
		{
			"name": "ashgate", "bpm": 104, "root": 60, "scale": "harmonic", "density": "mid", "rest": 0.08,
			"form": ["A", "B", "A2", "B2"],
			"prog": {"A": [0, 0, 5, 4, 0, 3, 4, 4], "B": [5, 3, 0, 4, 5, 3, 4, 4]},
			"lead": {"wave": PULSE, "duty": 0.5, "a": 0.01, "d": 0.25, "s": 0.6, "r": 0.08, "vib": 0.006},
			"lead_vol": 0.22,
			"bass": "march", "bass_inst": {"wave": PULSE, "duty": 0.5, "a": 0.004, "d": 0.12, "s": 0.4, "r": 0.03}, "bass_vol": 0.17,
			"arp": "stab", "arp_inst": {"wave": PULSE, "duty": 0.25, "a": 0.003, "d": 0.1, "s": 0.0, "r": 0.03}, "arp_vol": 0.05,
			"drums": {"kick": "x.......x.......", "snare": "x..x..x.x.xx..x.", "hat": ""},
			"drums2": {"kick": "x...x...x...x...", "snare": "x.xx..x.x.xx.xxx", "hat": "..x...x...x...x."},
			"echo": [0.5, 0.18], "lowpass": 3600.0, "loudness": 0.17,
		},
		# Forest Outskirts: an adventurous, driving E minor.
		{
			"name": "forest", "bpm": 132, "root": 64, "scale": "minor", "density": "fast", "rest": 0.08,
			"form": ["A", "B", "A2", "B2"],
			"prog": {"A": [0, 5, 2, 6, 0, 5, 6, 6], "B": [3, 4, 0, 0, 3, 4, 6, 6]},
			"lead": {"wave": PULSE, "duty": 0.25, "a": 0.008, "d": 0.15, "s": 0.6, "r": 0.05, "vib": 0.007},
			"lead_vol": 0.25,
			"bass": "octave8", "bass_inst": {"wave": TRI, "a": 0.003, "d": 0.12, "s": 0.6, "r": 0.03}, "bass_vol": 0.36,
			"arp": "arp16", "arp_inst": {"wave": PULSE, "duty": 0.125, "a": 0.002, "d": 0.07, "s": 0.0, "r": 0.02}, "arp_vol": 0.06,
			"drums": {"kick": "x.....x...x.....", "snare": "....x.......x...", "hat": "x.x.x.x.x.x.x.x."},
			"drums2": {"kick": "x.....x...x...x.", "snare": "....x.......x..g", "hat": "xgxgxgxgxgxgxgxg"},
			"echo": [0.75, 0.22], "lowpass": 5200.0, "loudness": 0.17,
		},
		# Sunscorch Sands: a hot, galloping D phrygian dominant.
		{
			"name": "desert", "bpm": 124, "root": 62, "scale": "phrygian_dominant", "density": "fast", "rest": 0.1,
			"form": ["A", "B", "A2", "B2"],
			"prog": {"A": [0, 0, 1, 0, 0, 0, 6, 1], "B": [3, 3, 6, 6, 1, 1, 0, 0]},
			"lead": {"wave": PULSE, "duty": 0.125, "a": 0.01, "d": 0.2, "s": 0.6, "r": 0.06, "vib": 0.01, "vib_rate": 6.5, "slide": 1.0},
			"lead_vol": 0.25,
			"bass": "gallop", "bass_inst": {"wave": TRI, "a": 0.003, "d": 0.1, "s": 0.5, "r": 0.03}, "bass_vol": 0.36,
			"arp": "stab", "arp_inst": {"wave": PULSE, "duty": 0.25, "a": 0.002, "d": 0.08, "s": 0.0, "r": 0.02}, "arp_vol": 0.05,
			"drums": {"kick": "x.....x.x.......", "tom": "...x.....x.x..x.", "shaker": "x.x.x.x.x.x.x.x.", "snare": "....x.......x..."},
			"echo": [0.75, 0.2], "lowpass": 4800.0, "loudness": 0.17,
		},
		# The Ice Caves: cold and echoing, B minor, sparse drums.
		{
			"name": "ice_caves", "bpm": 104, "root": 71, "scale": "minor", "density": "mid", "rest": 0.15,
			"form": ["A", "B", "A2", "B2"],
			"prog": {"A": [0, 5, 3, 4, 0, 5, 6, 4], "B": [5, 6, 0, 0, 5, 6, 4, 4]},
			"lead": {"wave": TRI, "a": 0.01, "d": 0.3, "s": 0.6, "r": 0.12, "vib": 0.008, "detune": 0.004},
			"lead_vol": 0.34,
			"bass": "half", "bass_inst": {"wave": PULSE, "duty": 0.25, "a": 0.01, "d": 0.4, "s": 0.5, "r": 0.1}, "bass_vol": 0.14,
			"arp": "arp16", "arp_inst": {"wave": SINE, "a": 0.002, "d": 0.12, "s": 0.0, "r": 0.05}, "arp_vol": 0.11,
			"drums": {"kick": "x.......x.......", "hat": "....x.......x..."},
			"drums2": {"kick": "x.......x.....x.", "snare": "....g.......g...", "hat": "..x...x...x...x."},
			"echo": [0.75, 0.42], "lowpass": 4200.0, "loudness": 0.15,
		},
		# The Underworld: fast and heavy, C# harmonic minor.
		{
			"name": "underworld", "bpm": 140, "root": 61, "scale": "harmonic", "density": "fast", "rest": 0.08,
			"form": ["A", "B", "A2", "B2"],
			"prog": {"A": [0, 0, 5, 5, 3, 3, 4, 4], "B": [0, 5, 3, 4, 0, 5, 4, 4]},
			"lead": {"wave": SAW, "a": 0.008, "d": 0.2, "s": 0.6, "r": 0.05, "vib": 0.008},
			"lead_vol": 0.2,
			"bass": "octave8", "bass_inst": {"wave": PULSE, "duty": 0.5, "a": 0.003, "d": 0.1, "s": 0.5, "r": 0.02}, "bass_vol": 0.18,
			"arp": "arp16", "arp_inst": {"wave": PULSE, "duty": 0.25, "a": 0.002, "d": 0.06, "s": 0.0, "r": 0.02}, "arp_vol": 0.05,
			"drums": {"kick": "x.x...x.x.x...x.", "snare": "....x.......x...", "hat": "xgxgxgxgxgxgxgxg"},
			"drums2": {"kick": "x.x.x.x.x.x.x.x.", "snare": "....x.......x.x.", "hat": "xgxgxgxgxgxgxgxg"},
			"echo": [0.5, 0.18], "lowpass": 4200.0, "loudness": 0.18,
		},
		# Boss fights: urgent F# harmonic minor.
		{
			"name": "boss", "bpm": 152, "root": 66, "scale": "harmonic", "density": "fast", "rest": 0.05,
			"form": ["A", "B"],
			"prog": {"A": [0, 0, 5, 4, 3, 3, 5, 4], "B": [5, 3, 0, 4, 5, 3, 4, 4]},
			"lead": {"wave": PULSE, "duty": 0.5, "a": 0.005, "d": 0.15, "s": 0.65, "r": 0.04, "vib": 0.008},
			"lead_vol": 0.2, "harmony": true,
			"bass": "sixteen", "bass_inst": {"wave": TRI, "a": 0.002, "d": 0.06, "s": 0.6, "r": 0.02}, "bass_vol": 0.36,
			"arp": "arp16", "arp_inst": {"wave": PULSE, "duty": 0.125, "a": 0.002, "d": 0.06, "s": 0.0, "r": 0.02}, "arp_vol": 0.05,
			"drums": {"kick": "x...x...x...x...", "snare": "....x.......x...", "hat": "xxxxxxxxxxxxxxxx"},
			"echo": [0.5, 0.15], "lowpass": 5000.0, "loudness": 0.18,
		},
		# Loading screens: calm, slow F major pads and a soft bell.
		{
			"name": "loading", "bpm": 70, "root": 65, "scale": "major", "density": "calm", "rest": 0.25,
			"form": ["A", "B"],
			"prog": {"A": [0, 3, 5, 4, 0, 3, 4, 0], "B": [3, 0, 5, 4, 3, 0, 4, 4]},
			"lead": {"wave": SINE, "a": 0.01, "d": 0.7, "s": 0.0, "r": 0.4, "detune": 0.003},
			"lead_vol": 0.32,
			"bass": "drone", "bass_inst": {"wave": SINE, "a": 0.3, "d": 2.0, "s": 0.7, "r": 0.5}, "bass_vol": 0.3,
			"arp": "pad", "arp_inst": {"wave": TRI, "a": 0.5, "d": 2.0, "s": 0.7, "r": 0.6, "detune": 0.004}, "arp_vol": 0.06,
			"drums": no_drums, "echo": [0.75, 0.45], "lowpass": 3000.0, "loudness": 0.12,
		},
	]


func _render_track(spec: Dictionary) -> PackedFloat32Array:
	var step := 60.0 / float(spec["bpm"]) / 4.0
	var form: Array = spec["form"]
	var loop_length := int(float(form.size() * BARS_PER_SECTION * 16) * step * RATE)
	var full_length := loop_length + int(TAIL_SECONDS * RATE)
	var dry := PackedFloat32Array()
	dry.resize(full_length)
	var wet := PackedFloat32Array()
	wet.resize(full_length)
	var scale: Array = SCALES[spec["scale"]]
	var root: int = spec["root"]
	var melodies := {}

	for section_index in form.size():
		var section: String = form[section_index]
		var key := section.substr(0, 1)
		var variant := section.length() > 1
		var progression: Array = spec["prog"][key]
		if not melodies.has(key):
			melodies[key] = _write_melody(spec, progression, hash(str(spec["name"]) + key))
		var section_start := float(section_index * BARS_PER_SECTION * 16) * step
		var lead_volume: float = spec["lead_vol"]
		for note: Array in melodies[key]:
			var start := section_start + float(note[0]) * step
			var length := float(note[1]) * step * 0.9
			_note(wet, start, length, _degree_midi(note[2], root, scale), spec["lead"], lead_volume)
			if variant or spec.get("harmony", false):
				_note(wet, start, length, _degree_midi(note[2] - 2, root, scale), spec["lead"], lead_volume * 0.42)
		for bar in BARS_PER_SECTION:
			var chord: int = progression[bar]
			var bar_start := section_start + float(bar * 16) * step
			_bass_bar(dry, bar_start, step, chord, spec, scale)
			_arp_bar(wet, bar_start, step, chord, spec, scale, variant)
			var drums: Dictionary = spec.get("drums2", spec["drums"]) if variant else spec["drums"]
			_drum_bar(dry, bar_start, step, drums, bar == BARS_PER_SECTION - 1)

	var echo: Array = spec["echo"]
	_echo(wet, int(float(echo[0]) * 4.0 * step * RATE), echo[1])
	for i in full_length:
		dry[i] += wet[i]
	_lowpass(dry, spec["lowpass"])
	_lowpass(dry, spec["lowpass"] * 1.5)
	# Whatever rings past the loop point (echoes, releases) plays over the loop's start instead.
	for i in full_length - loop_length:
		dry[i] += dry[loop_length + i]
	dry.resize(loop_length)
	return _master(dry, spec["loudness"])


## A seeded melody for one 8-bar section: a 2-bar motif, an answer, the motif again moved onto the new
## chords, and a cadence that comes home to a chord root. Notes are [start 16th, length 16ths, degree].
func _write_melody(spec: Dictionary, progression: Array, seed_value: int) -> Array:
	rng.seed = seed_value
	var rhythms: Array = RHYTHMS[spec["density"]]
	var rest_chance: float = spec["rest"]
	var notes: Array = []
	var motif: Array = []
	var previous := 4
	for phrase in 4:
		var first_bar := phrase * 2
		if phrase == 2:
			var shift := _wrap_shift(int(progression[first_bar]) - int(progression[0]))
			for motif_note: Array in motif:
				var degree: int = motif_note[2] + shift
				notes.append([first_bar * 16 + motif_note[0], motif_note[1], degree])
				previous = degree
			continue
		for bar_in_phrase in 2:
			var bar := first_bar + bar_in_phrase
			var chord: int = progression[bar]
			var rhythm: Array = rhythms[rng.randi() % rhythms.size()]
			var position := 0
			for index in rhythm.size():
				var length: int = rhythm[index]
				var phrase_end := bar_in_phrase == 1 and index == rhythm.size() - 1
				if position > 0 and not phrase_end and rng.randf() < rest_chance:
					position += length
					continue
				var degree: int
				if phrase == 3 and phrase_end:
					degree = _nearest_chord_tone(previous, chord, [0])
				elif position % 4 == 0:
					degree = _nearest_chord_tone(previous + rng.randi_range(-2, 2), chord, [0, 2, 4])
				else:
					degree = previous + [-1, 1, -1, 1, 2, -2][rng.randi() % 6]
				degree = clampi(degree, -2, 9)
				var note_length := length
				if phrase_end and phrase in [1, 3]:
					note_length = maxi(length - 2, 2)
				notes.append([bar * 16 + position, note_length, degree])
				if phrase == 0:
					motif.append([bar * 16 + position, note_length, degree])
				previous = degree
				position += length
	return notes


func _wrap_shift(shift: int) -> int:
	shift = posmod(shift, 7)
	return shift - 7 if shift > 3 else shift


## The degree nearest `target` whose distance from the chord root is one of `tones` (0 root, 2 third, 4 fifth).
func _nearest_chord_tone(target: int, chord: int, tones: Array) -> int:
	for distance in 4:
		for candidate in [target + distance, target - distance]:
			if posmod(candidate - chord, 7) in tones:
				return candidate
	return target


func _degree_midi(degree: int, root: int, scale: Array) -> int:
	return root + 12 * floori(float(degree) / 7.0) + int(scale[posmod(degree, 7)])


func _bass_bar(buffer: PackedFloat32Array, bar_start: float, step: float, chord: int, spec: Dictionary, scale: Array) -> void:
	var bass_root: int = spec["root"] - 24
	var root_note := _degree_midi(chord % 7, bass_root, scale)
	var third := _degree_midi(chord % 7 + 2, bass_root, scale)
	var fifth := _degree_midi(chord % 7 + 4, bass_root, scale)
	var instrument: Dictionary = spec["bass_inst"]
	var volume: float = spec["bass_vol"]
	# [16th, length, midi]
	var hits: Array = []
	match String(spec["bass"]):
		"half":
			hits = [[0, 8, root_note], [8, 8, fifth]]
		"walk":
			hits = [[0, 4, root_note], [4, 4, third], [8, 4, fifth], [12, 4, root_note + 12]]
		"drone":
			hits = [[0, 16, root_note]]
		"octave8":
			for i in 8:
				hits.append([i * 2, 2, root_note + (12 if i % 2 == 1 else 0)])
		"gallop":
			for beat in 4:
				hits.append_array([[beat * 4, 2, root_note], [beat * 4 + 2, 1, root_note], [beat * 4 + 3, 1, root_note + 12]])
		"sixteen":
			for i in 16:
				hits.append([i, 1, root_note + (12 if i % 4 == 2 else 0)])
		"march":
			for i in 8:
				hits.append([i * 2, 2, fifth if i % 4 == 2 else root_note])
	for hit: Array in hits:
		_note(buffer, bar_start + float(hit[0]) * step, float(hit[1]) * step * 0.85, hit[2], instrument, volume)


func _arp_bar(buffer: PackedFloat32Array, bar_start: float, step: float, chord: int, spec: Dictionary, scale: Array, variant: bool) -> void:
	var arp_root: int = spec["root"] - 12
	var instrument: Dictionary = spec["arp_inst"]
	var volume: float = spec["arp_vol"] * (1.2 if variant else 1.0)
	var base := chord % 7
	match String(spec["arp"]):
		"arp16":
			var tones := [0, 2, 4, 7]
			for i in 16:
				_note(buffer, bar_start + float(i) * step, step * 0.8, _degree_midi(base + tones[i % 4], arp_root, scale), instrument, volume)
		"broken8":
			var tones := [0, 4, 7, 9, 7, 4, 2, 4]
			for i in 8:
				_note(buffer, bar_start + float(i * 2) * step, step * 1.8, _degree_midi(base + tones[i], arp_root, scale), instrument, volume)
		"pad":
			for tone in [0, 2, 4]:
				_note(buffer, bar_start, step * 16.0, _degree_midi(base + tone, arp_root, scale), instrument, volume)
		"stab":
			for beat in 4:
				for tone in [0, 2, 4]:
					_note(buffer, bar_start + float(beat * 4 + 2) * step, step * 1.2, _degree_midi(base + tone, arp_root + 12, scale), instrument, volume)
		"bell":
			for beat in 4:
				if rng.randf() < 0.3:
					continue
				var tone: int = [0, 2, 4, 7, 9][rng.randi() % 5]
				_note(buffer, bar_start + float(beat * 4) * step, step * 3.0, _degree_midi(base + tone, arp_root + 24, scale), instrument, volume)


func _drum_bar(buffer: PackedFloat32Array, bar_start: float, step: float, drums: Dictionary, fill: bool) -> void:
	for kind: String in drums:
		var pattern: String = drums[kind]
		if fill and kind == "snare" and not pattern.is_empty():
			pattern = "....x.....x.xgxx"
		for i in pattern.length():
			var hit := pattern[i]
			if hit == "x" or hit == "g":
				_drum(buffer, bar_start + float(i) * step, kind, 1.0 if hit == "x" else 0.45)


## One note on a buffer. The instrument holds the waveform and an ADSR envelope, plus optional vibrato,
## a detuned second oscillator (a soft chorus) and a scoop up into the pitch.
func _note(buffer: PackedFloat32Array, start_time: float, duration: float, midi: float, instrument: Dictionary, volume: float) -> void:
	var wave: int = instrument["wave"]
	var duty: float = instrument.get("duty", 0.5)
	var attack: float = maxf(float(instrument.get("a", 0.005)), 0.001)
	var decay: float = maxf(float(instrument.get("d", 0.2)), 0.001)
	var sustain: float = instrument.get("s", 0.6)
	var release: float = instrument.get("r", 0.05)
	var vibrato: float = instrument.get("vib", 0.0)
	var vibrato_rate: float = instrument.get("vib_rate", 5.5)
	var detune: float = instrument.get("detune", 0.0)
	var slide: float = instrument.get("slide", 0.0)
	var frequency := 440.0 * pow(2.0, (midi - 69.0) / 12.0)
	var start := int(start_time * RATE)
	var held := int(duration * RATE)
	var total := held + int(release * RATE)
	var phase := 0.0
	var phase2 := 0.25
	var release_from := 1.0
	for k in total:
		var index := start + k
		if index >= buffer.size():
			break
		var t := float(k) / RATE
		var envelope: float
		if k < held:
			envelope = t / attack if t < attack else sustain + (1.0 - sustain) * exp(-(t - attack) / decay)
			release_from = envelope
		else:
			envelope = release_from * (1.0 - float(k - held) / float(total - held))
		var f := frequency
		if vibrato > 0.0 and t > 0.15:
			f *= 1.0 + vibrato * sin(TAU * vibrato_rate * t) * minf((t - 0.15) * 4.0, 1.0)
		if slide > 0.0 and t < 0.05:
			f *= pow(2.0, -slide * (1.0 - t / 0.05) / 12.0)
		phase += f / RATE
		var sample := _oscillator(wave, phase, duty)
		if detune > 0.0:
			phase2 += f * (1.0 + detune) / RATE
			sample = 0.5 * (sample + _oscillator(wave, phase2, duty))
		buffer[index] += sample * envelope * volume


func _oscillator(wave: int, phase: float, duty: float) -> float:
	var p := phase - floorf(phase)
	match wave:
		PULSE:
			return 1.0 if p < duty else -1.0
		TRI:
			return 1.0 - 4.0 * absf(p - 0.5)
		SAW:
			return 2.0 * p - 1.0
		SINE:
			return sin(TAU * p)
	return rng.randf_range(-1.0, 1.0)


func _drum(buffer: PackedFloat32Array, start_time: float, kind: String, volume: float) -> void:
	var start := int(start_time * RATE)
	var length := int(0.2 * RATE)
	var phase := 0.0
	var low := 0.0
	for k in length:
		var index := start + k
		if index >= buffer.size():
			break
		var t := float(k) / RATE
		var sample := 0.0
		match kind:
			"kick":
				phase += (42.0 + 110.0 * exp(-t / 0.03)) / RATE
				sample = sin(TAU * phase) * exp(-t / 0.07) * 0.55
			"snare":
				phase += 190.0 / RATE
				sample = rng.randf_range(-1.0, 1.0) * exp(-t / 0.05) * 0.22 + sin(TAU * phase) * exp(-t / 0.03) * 0.18
			"hat":
				var noise := rng.randf_range(-1.0, 1.0)
				low += 0.5 * (noise - low)
				sample = (noise - low) * exp(-t / 0.012) * 0.12
			"shaker":
				var noise := rng.randf_range(-1.0, 1.0)
				low += 0.35 * (noise - low)
				sample = (noise - low) * minf(t / 0.008, 1.0) * exp(-t / 0.03) * 0.09
			"tom":
				phase += (95.0 + 70.0 * exp(-t / 0.05)) / RATE
				sample = sin(TAU * phase) * exp(-t / 0.09) * 0.38
		buffer[index] += sample * volume


func _echo(buffer: PackedFloat32Array, delay: int, feedback: float) -> void:
	for i in range(delay, buffer.size()):
		buffer[i] += buffer[i - delay] * feedback


func _lowpass(buffer: PackedFloat32Array, cutoff: float) -> void:
	var a := 1.0 - exp(-TAU * cutoff / RATE)
	var state := 0.0
	for i in buffer.size():
		state += a * (buffer[i] - state)
		buffer[i] = state


## Brings a track to a target loudness (RMS), then rounds off any peaks so nothing clips.
func _master(buffer: PackedFloat32Array, loudness: float) -> PackedFloat32Array:
	var sum := 0.0
	for sample in buffer:
		sum += sample * sample
	var gain := loudness / maxf(sqrt(sum / float(buffer.size())), 0.0001)
	for i in buffer.size():
		buffer[i] = tanh(buffer[i] * gain * 1.1) * 0.9
	return buffer


# --- Sound effects ----------------------------------------------------------------------------------


func _hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


## A sound layer: [wave, start, duration, start Hz, end Hz, volume, options]. For noise the frequency is
## how often a new random value is picked (lower = grittier). Options: a (attack), shape (exp, lin,
## flat, swell), duty, vib, vib_rate, lp, lp1 (a low-pass sweep), hp, trem, trem_rate.
func L(wave: int, start: float, duration: float, from_hz: float, to_hz: float, volume: float, options := {}) -> Array:
	return [wave, start, duration, from_hz, to_hz, volume, options]


## A run of notes as layers: each entry is [midi, start, duration].
func _tones(notes: Array, wave: int, volume: float, options := {}) -> Array:
	var layers: Array = []
	for note: Array in notes:
		layers.append(L(wave, note[1], note[2], _hz(note[0]), _hz(note[0]), volume, options))
	return layers


func _twang(start: float, from_hz := 900.0, volume := 1.0) -> Array:
	return [
		L(TRI, start, 0.09, from_hz, from_hz * 0.55, 0.9 * volume),
		L(PULSE, start, 0.025, 2000.0, 1800.0, 0.25 * volume, {"duty": 0.25}),
		L(NOISE, start, 0.12, RATE, RATE, 0.45 * volume, {"shape": "swell", "lp": 4500.0, "lp1": 1500.0, "hp": 800.0}),
	]


## name -> [layers, peak level]
func _sounds() -> Dictionary:
	var sounds := {
		# Interface and interactions.
		"ui_click": [[L(PULSE, 0, 0.035, 1400, 1100, 1.0, {"shape": "lin", "lp": 5000.0})], 0.35],
		"ui_open": [_tones([[76, 0.0, 0.05], [83, 0.05, 0.09]], PULSE, 0.7, {"duty": 0.25, "lp": 6000.0}), 0.4],
		"ui_close": [_tones([[83, 0.0, 0.05], [76, 0.05, 0.08]], PULSE, 0.7, {"duty": 0.25, "lp": 6000.0}), 0.35],
		"equip": [[
			L(PULSE, 0, 0.12, 2200, 2100, 0.5),
			L(SINE, 0, 0.2, 3300, 3300, 0.5),
			L(NOISE, 0, 0.03, RATE, RATE, 0.4, {"hp": 3000.0}),
		], 0.45],
		"coin": [_tones([[83, 0.0, 0.07], [88, 0.07, 0.28]], PULSE, 0.6, {"duty": 0.5, "lp": 7000.0}), 0.4],
		"item_pickup": [_tones([[72, 0.0, 0.12], [76, 0.05, 0.12], [79, 0.1, 0.12], [84, 0.15, 0.2]], TRI, 0.6), 0.45],
		"potion": [[
			L(SINE, 0, 0.36, 300, 700, 0.7, {"shape": "swell", "vib": 0.15, "vib_rate": 22.0}),
			L(SINE, 0.06, 0.05, 800, 1400, 0.3),
			L(SINE, 0.16, 0.05, 900, 1500, 0.3),
			L(SINE, 0.26, 0.05, 1000, 1700, 0.3),
		], 0.45],
		"level_up": [
			_tones([[60, 0.0, 0.12], [64, 0.08, 0.12], [67, 0.16, 0.12], [72, 0.24, 0.14]], PULSE, 0.5, {"duty": 0.25, "lp": 6000.0})
			+ _tones([[72, 0.36, 0.7], [76, 0.36, 0.7], [79, 0.36, 0.7]], TRI, 0.45, {"vib": 0.006, "vib_rate": 6.0})
			+ _tones([[84, 0.42, 0.15], [88, 0.47, 0.15], [91, 0.52, 0.15], [96, 0.57, 0.25]], SINE, 0.25),
			0.6,
		],
		"quest_accept": [
			_tones([[67, 0.0, 0.1], [72, 0.1, 0.28]], TRI, 0.8) + _tones([[64, 0.1, 0.28]], PULSE, 0.2, {"duty": 0.25, "lp": 4000.0}),
			0.45,
		],
		"quest_complete": [
			_tones([[72, 0.0, 0.1], [76, 0.1, 0.1], [79, 0.2, 0.1], [84, 0.3, 0.5]], PULSE, 0.5, {"duty": 0.25, "lp": 6000.0})
			+ _tones([[48, 0.0, 0.3], [55, 0.3, 0.5]], TRI, 0.6),
			0.55,
		],
		"chest_open": [
			[
				L(SAW, 0, 0.35, 90, 130, 0.5, {"shape": "swell", "vib": 0.08, "vib_rate": 30.0, "lp": 900.0}),
				L(NOISE, 0.3, 0.1, 6000, 6000, 0.6, {"lp": 700.0}),
			]
			+ _tones([[79, 0.36, 0.2], [84, 0.42, 0.2], [88, 0.48, 0.2], [91, 0.54, 0.3]], SINE, 0.35),
			0.55,
		],
		# Rises over the town portal's 3 second channel.
		"portal_cast": [[
			L(SINE, 0, 3.0, 180, 720, 0.6, {"a": 1.5, "shape": "flat", "vib": 0.03, "vib_rate": 7.0}),
			L(TRI, 0, 3.0, 270, 1080, 0.2, {"a": 2.5, "shape": "flat", "vib": 0.02, "vib_rate": 9.0}),
			L(NOISE, 0, 3.0, RATE, RATE, 0.1, {"a": 2.0, "shape": "flat", "hp": 4000.0, "trem": 0.6, "trem_rate": 5.0}),
		], 0.35],
		"portal_open": [
			[L(NOISE, 0, 0.6, RATE, RATE, 0.5, {"shape": "swell", "lp": 400.0, "lp1": 4000.0})]
			+ _tones([[72, 0.1, 0.8], [79, 0.1, 0.8], [84, 0.1, 0.8]], SINE, 0.35, {"vib": 0.01, "vib_rate": 7.0}),
			0.5,
		],
		"portal_enter": [[
			L(NOISE, 0, 0.7, RATE, RATE, 0.8, {"shape": "swell", "lp": 3000.0, "lp1": 300.0}),
			L(SINE, 0, 0.7, 900, 200, 0.3, {"shape": "swell"}),
		], 0.5],
		"waystone": [[
			L(SINE, 0, 1.3, _hz(48), _hz(48), 0.6, {"vib": 0.004}),
			L(SINE, 0, 1.2, _hz(55), _hz(55), 0.4),
			L(SINE, 0.05, 1.1, _hz(64), _hz(64), 0.3),
			L(SINE, 0.1, 0.9, _hz(76), _hz(76), 0.15),
			L(NOISE, 0, 0.03, RATE, RATE, 0.3, {"lp": 2000.0}),
		], 0.5],
		"boss_incoming": [[
			L(SAW, 0, 0.5, _hz(41), _hz(41), 0.5, {"shape": "flat", "lp": 900.0, "vib": 0.01}),
			L(SAW, 0.45, 1.1, _hz(40), _hz(39), 0.55, {"lp": 800.0, "vib": 0.012}),
			L(PULSE, 0, 1.5, _hz(28), _hz(27), 0.25, {"lp": 400.0}),
			L(NOISE, 0, 1.5, 3000, 3000, 0.5, {"shape": "swell", "lp": 200.0}),
		], 0.75],
		"level_complete": [
			_tones([[60, 0.0, 0.12], [64, 0.12, 0.12], [67, 0.24, 0.12], [72, 0.36, 0.12], [76, 0.48, 0.4]], PULSE, 0.5, {"duty": 0.5, "lp": 5000.0, "shape": "flat"})
			+ _tones([[72, 0.9, 1.0], [76, 0.9, 1.0], [79, 0.9, 1.0], [84, 0.9, 1.0]], TRI, 0.4, {"vib": 0.006})
			+ _tones([[48, 0.0, 0.45], [43, 0.45, 0.45], [48, 0.9, 1.0]], TRI, 0.6),
			0.65,
		],
		"death": [
			_tones([[67, 0.0, 0.3], [66, 0.3, 0.3], [65, 0.6, 0.3]], TRI, 0.7, {"shape": "flat"})
			+ [L(TRI, 0.9, 1.0, _hz(64), _hz(62), 0.7, {"vib": 0.025, "vib_rate": 5.0})]
			+ _tones([[43, 0.0, 0.9], [40, 0.9, 1.0]], PULSE, 0.15, {"duty": 0.125, "lp": 1500.0}),
			0.55,
		],
		"dodge": [[L(NOISE, 0, 0.12, RATE, RATE, 0.5, {"shape": "swell", "lp": 6000.0, "lp1": 2000.0, "hp": 1500.0})], 0.3],

		# Combat.
		"sword_swing": [[L(NOISE, 0, 0.16, RATE, RATE, 1.0, {"shape": "swell", "lp": 1500.0, "lp1": 5000.0, "hp": 600.0})], 0.45],
		"enemy_hit": [[
			L(NOISE, 0, 0.08, 9000, 9000, 0.8, {"lp": 3000.0, "lp1": 800.0}),
			L(SINE, 0, 0.09, 180, 70, 0.9),
			L(PULSE, 0, 0.03, 400, 200, 0.25),
		], 0.5],
		"heavy_hit": [[
			L(NOISE, 0, 0.16, 8000, 8000, 0.9, {"lp": 2500.0, "lp1": 500.0}),
			L(SINE, 0, 0.18, 140, 45, 1.0),
			L(PULSE, 0, 0.06, 300, 120, 0.4),
		], 0.65],
		"enemy_death": [[
			L(PULSE, 0, 0.3, 500, 80, 0.5, {"lp": 3000.0}),
			L(NOISE, 0, 0.25, 7000, 7000, 0.5, {"lp": 1500.0, "lp1": 300.0}),
		], 0.5],
		"player_hurt": [[
			L(PULSE, 0, 0.14, 330, 160, 0.7, {"lp": 2200.0}),
			L(NOISE, 0, 0.06, RATE, RATE, 0.4, {"lp": 2000.0}),
		], 0.5],
		"arrow_shot": [_twang(0.0), 0.4],
		"fireball": [[
			L(NOISE, 0, 0.35, RATE, RATE, 0.8, {"shape": "swell", "lp": 600.0, "lp1": 2500.0, "hp": 200.0}),
			L(SAW, 0, 0.3, 120, 260, 0.3, {"lp": 800.0}),
		], 0.45],
		"fire_impact": [[
			L(NOISE, 0, 0.3, 11000, 11000, 1.0, {"lp": 2500.0, "lp1": 300.0}),
			L(SINE, 0, 0.25, 100, 40, 0.8),
		], 0.5],
		"iceball": [[
			L(SINE, 0, 0.18, 1500, 2600, 0.6),
			L(TRI, 0.03, 0.15, 2200, 3200, 0.3),
			L(NOISE, 0, 0.15, RATE, RATE, 0.3, {"shape": "swell", "hp": 4000.0}),
		], 0.35],
		"ice_impact": [[
			L(NOISE, 0, 0.18, RATE, RATE, 0.6, {"hp": 3000.0}),
			L(SINE, 0, 0.25, 3100, 3100, 0.4),
			L(SINE, 0.02, 0.25, 4150, 4150, 0.3),
			L(PULSE, 0, 0.1, 2600, 2000, 0.2, {"duty": 0.125}),
		], 0.4],
		"explosion": [[
			L(NOISE, 0, 0.7, 8000, 8000, 1.0, {"lp": 3000.0, "lp1": 150.0}),
			L(SINE, 0, 0.5, 90, 30, 1.0),
		], 0.75],
		"eruption": [[
			L(NOISE, 0, 0.45, 9000, 9000, 0.8, {"shape": "swell", "lp": 300.0, "lp1": 2000.0}),
			L(SINE, 0, 0.4, 60, 90, 0.5, {"shape": "swell"}),
		], 0.5],
		"enemy_attack": [[
			L(NOISE, 0, 0.14, RATE, RATE, 0.7, {"shape": "swell", "lp": 900.0, "lp1": 2500.0, "hp": 300.0}),
			L(SAW, 0, 0.12, 140, 90, 0.3, {"lp": 600.0}),
		], 0.4],
		"enemy_spell": [[
			L(PULSE, 0, 0.25, 900, 300, 0.5, {"duty": 0.25, "vib": 0.05, "vib_rate": 25.0, "lp": 3500.0}),
			L(NOISE, 0, 0.1, RATE, RATE, 0.3, {"hp": 2000.0}),
		], 0.38],

		# Warrior skills.
		"skill_heavy_strike": [[
			L(NOISE, 0, 0.25, RATE, RATE, 0.8, {"shape": "swell", "lp": 800.0, "lp1": 3500.0, "hp": 300.0}),
			L(SINE, 0, 0.2, 160, 60, 0.5),
		], 0.55],
		"skill_shield_bash": [[
			L(SINE, 0, 0.4, 410, 410, 0.5),
			L(SINE, 0, 0.35, 637, 637, 0.4),
			L(SINE, 0, 0.3, 1060, 1060, 0.3),
			L(SINE, 0, 0.25, 1590, 1590, 0.2),
			L(NOISE, 0, 0.04, RATE, RATE, 0.7, {"lp": 5000.0}),
			L(SINE, 0, 0.12, 120, 60, 0.7),
		], 0.55],
		"skill_cleave": [[
			L(NOISE, 0, 0.32, RATE, RATE, 0.8, {"shape": "swell", "lp": 1000.0, "lp1": 5000.0, "hp": 400.0}),
			L(NOISE, 0.05, 0.25, RATE, RATE, 0.4, {"shape": "swell", "lp": 3000.0, "lp1": 1200.0, "hp": 600.0}),
		], 0.55],
		"skill_leap_slam": [[
			L(SINE, 0, 0.08, 300, 700, 0.3, {"shape": "swell"}),
			L(SINE, 0.06, 0.5, 120, 35, 1.0),
			L(NOISE, 0.06, 0.6, 9000, 9000, 1.0, {"lp": 2000.0, "lp1": 150.0}),
		], 0.75],
		"skill_war_cry": [[
			L(SAW, 0, 0.7, _hz(50), _hz(52), 0.5, {"shape": "flat", "lp": 1600.0, "vib": 0.02, "vib_rate": 6.0}),
			L(SAW, 0, 0.7, _hz(57), _hz(59), 0.4, {"shape": "flat", "lp": 1600.0, "vib": 0.02, "vib_rate": 6.0}),
			L(PULSE, 0, 0.7, _hz(62), _hz(64), 0.25, {"shape": "flat", "duty": 0.25, "lp": 2000.0}),
			L(NOISE, 0, 0.7, RATE, RATE, 0.15, {"shape": "swell", "lp": 800.0}),
		], 0.6],
		"skill_iron_resolve": [[
			L(SINE, 0, 0.8, _hz(60), _hz(60), 0.5, {"vib": 0.006}),
			L(SINE, 0, 0.8, _hz(67), _hz(67), 0.4),
			L(SINE, 0.05, 0.8, _hz(72), _hz(72), 0.35),
			L(PULSE, 0, 0.6, _hz(48), _hz(48), 0.3, {"shape": "swell", "lp": 700.0}),
		], 0.5],
		"skill_execute": [[
			L(NOISE, 0, 0.1, RATE, RATE, 0.6, {"shape": "swell", "lp": 6000.0, "hp": 2000.0}),
			L(PULSE, 0, 0.08, 1600, 400, 0.4, {"duty": 0.25}),
			L(SINE, 0.1, 0.25, 130, 40, 1.0),
			L(NOISE, 0.1, 0.15, 9000, 9000, 0.7, {"lp": 1500.0, "lp1": 300.0}),
		], 0.65],
		"skill_whirlwind": [[
			L(NOISE, 0, 0.7, RATE, RATE, 0.9, {"shape": "swell", "lp": 800.0, "lp1": 3000.0, "hp": 300.0, "trem": 0.8, "trem_rate": 9.0}),
		], 0.55],
		"skill_earthquake": [[
			L(NOISE, 0, 1.2, 3000, 3000, 1.0, {"lp": 300.0, "lp1": 120.0, "trem": 0.5, "trem_rate": 14.0}),
			L(SINE, 0, 1.0, 55, 35, 0.8),
			L(NOISE, 0, 0.3, 9000, 9000, 0.6, {"lp": 1500.0, "lp1": 300.0}),
			# The aftershock, 0.6 sec later.
			L(NOISE, 0.6, 0.35, 9000, 9000, 0.5, {"lp": 1200.0, "lp1": 250.0}),
			L(SINE, 0.6, 0.3, 80, 35, 0.6),
		], 0.8],
		"skill_second_wind": [
			_tones([[60, 0.0, 0.3], [64, 0.06, 0.3], [67, 0.12, 0.3], [72, 0.18, 0.3], [76, 0.24, 0.4]], TRI, 0.5, {"vib": 0.008})
			+ [L(SINE, 0, 0.7, _hz(84), _hz(84), 0.2, {"shape": "swell", "vib": 0.01})],
			0.45,
		],

		# Witch skills.
		"skill_firebolt": [[
			L(NOISE, 0, 0.3, RATE, RATE, 0.7, {"shape": "swell", "lp": 900.0, "lp1": 3500.0, "hp": 300.0}),
			L(PULSE, 0, 0.25, 300, 700, 0.3, {"duty": 0.25, "lp": 2000.0}),
		], 0.45],
		"skill_frost_nova": [
			[
				L(NOISE, 0, 0.5, RATE, RATE, 0.7, {"hp": 2500.0, "lp": 9000.0, "lp1": 3000.0}),
				L(SINE, 0, 0.4, 300, 120, 0.4),
			]
			+ _tones([[88, 0.0, 0.3], [91, 0.04, 0.3], [95, 0.08, 0.3], [100, 0.12, 0.3]], SINE, 0.3),
			0.55,
		],
		"skill_summon_wisp": [
			_tones([[72, 0.0, 0.35], [79, 0.07, 0.35], [84, 0.14, 0.35], [91, 0.21, 0.35]], SINE, 0.5, {"vib": 0.01})
			+ [L(TRI, 0, 0.6, 600, 1200, 0.2, {"shape": "swell", "vib": 0.02, "vib_rate": 7.0})],
			0.45,
		],
		"skill_soul_siphon": [[
			L(SINE, 0, 0.7, 900, 250, 0.6, {"shape": "swell", "vib": 0.06, "vib_rate": 12.0}),
			L(NOISE, 0, 0.7, RATE, RATE, 0.3, {"shape": "swell", "lp": 1200.0, "lp1": 400.0, "trem": 0.6, "trem_rate": 10.0}),
		], 0.5],
		"skill_arcane_shield": [[
			L(SINE, 0, 0.8, _hz(62), _hz(62), 0.4, {"shape": "swell", "vib": 0.01}),
			L(SINE, 0, 0.8, _hz(69), _hz(69), 0.35, {"shape": "swell"}),
			L(SINE, 0, 0.8, _hz(74), _hz(74), 0.3, {"shape": "swell"}),
			L(PULSE, 0, 0.8, _hz(86), _hz(86), 0.06, {"shape": "swell", "duty": 0.125}),
			L(NOISE, 0, 0.2, RATE, RATE, 0.15, {"hp": 5000.0}),
		], 0.45],
		"skill_curse": [[
			L(SAW, 0, 0.7, _hz(43), _hz(43), 0.5, {"shape": "swell", "vib": 0.04, "vib_rate": 4.0, "lp": 900.0}),
			L(SAW, 0, 0.7, _hz(44), _hz(44), 0.4, {"shape": "swell", "vib": 0.04, "vib_rate": 4.5, "lp": 900.0}),
			L(SINE, 0, 0.7, _hz(67), _hz(63), 0.2, {"shape": "swell"}),
		], 0.5],
		"skill_chain_lightning": [[
			L(NOISE, 0, 0.5, RATE, RATE, 0.8, {"hp": 1500.0, "trem": 0.9, "trem_rate": 30.0}),
			L(PULSE, 0, 0.5, 120, 90, 0.4, {"trem": 0.7, "trem_rate": 23.0, "lp": 3000.0}),
			L(NOISE, 0, 0.05, RATE, RATE, 1.0, {"hp": 1000.0}),
		], 0.55],
		"skill_meteor": [[
			L(SINE, 0, 0.7, 2400, 300, 0.5, {"shape": "flat"}),
			L(NOISE, 0, 0.7, RATE, RATE, 0.3, {"shape": "swell", "lp": 3000.0, "lp1": 600.0, "hp": 400.0}),
		], 0.45],
		"skill_wisp_swarm": [
			_tones([[84, 0.0, 0.2], [88, 0.07, 0.2], [91, 0.13, 0.2], [86, 0.2, 0.2], [93, 0.27, 0.2], [96, 0.34, 0.25]], SINE, 0.3, {"vib": 0.02})
			+ [L(TRI, 0, 0.6, 400, 900, 0.2, {"shape": "swell"})],
			0.45,
		],
		"skill_phase_step": [[
			L(PULSE, 0, 0.15, 400, 2000, 0.5, {"duty": 0.25, "lp": 4000.0}),
			L(PULSE, 0.1, 0.15, 2000, 600, 0.3, {"duty": 0.125, "lp": 4000.0}),
			L(NOISE, 0, 0.2, RATE, RATE, 0.2, {"shape": "swell", "hp": 3000.0}),
		], 0.4],

		# Ranger skills.
		"skill_power_shot": [
			_twang(0.0, 700.0) + [L(SINE, 0, 0.1, 150, 60, 0.5), L(NOISE, 0, 0.18, RATE, RATE, 0.4, {"shape": "swell", "lp": 5000.0, "lp1": 1500.0, "hp": 600.0})],
			0.5,
		],
		"skill_multi_shot": [_twang(0.0, 900.0) + _twang(0.04, 980.0, 0.8) + _twang(0.08, 840.0, 0.7), 0.5],
		"skill_explosive_arrow": [
			_twang(0.0, 800.0) + [L(NOISE, 0.05, 0.4, 6000, 6000, 0.3, {"hp": 2000.0, "trem": 0.5, "trem_rate": 25.0})],
			0.45,
		],
		"skill_smoke_bomb": [[
			L(NOISE, 0, 0.05, RATE, RATE, 0.6, {"hp": 1000.0}),
			L(NOISE, 0.02, 0.7, RATE, RATE, 0.7, {"shape": "swell", "lp": 1200.0, "lp1": 300.0}),
		], 0.45],
		"skill_hunters_mark": [[
			L(SINE, 0, 0.5, _hz(93), _hz(93), 0.6),
			L(SINE, 0.08, 0.5, _hz(100), _hz(100), 0.5),
			L(PULSE, 0, 0.03, 3000, 3000, 0.2),
		], 0.38],
		"skill_deadeye": [
			[L(SINE, 0, 0.35, 600, 2400, 0.4, {"shape": "swell"})]
			+ _twang(0.3, 1100.0)
			+ [L(PULSE, 0.3, 0.04, 3000, 3000, 0.3, {"duty": 0.125})],
			0.5,
		],
		"skill_rain_of_arrows": [
			[L(NOISE, 0, 0.6, RATE, RATE, 0.6, {"shape": "swell", "lp": 2000.0, "lp1": 5000.0, "hp": 1000.0, "trem": 0.5, "trem_rate": 18.0})]
			+ _twang(0.0, 900.0, 0.7) + _twang(0.05, 1000.0, 0.6) + _twang(0.1, 850.0, 0.6) + _twang(0.15, 950.0, 0.5),
			0.5,
		],
		"skill_barrage": [[
			L(NOISE, 0, 0.15, RATE, RATE, 0.5, {"shape": "swell", "lp": 1500.0, "hp": 500.0}),
			L(TRI, 0, 0.1, 600, 900, 0.4, {"shape": "swell"}),
		], 0.35],
		"skill_snare_trap": [[
			L(PULSE, 0, 0.04, 3000, 1500, 0.5),
			L(SINE, 0, 0.2, 1800, 1800, 0.4),
			L(SINE, 0, 0.2, 2650, 2650, 0.3),
			L(NOISE, 0, 0.05, RATE, RATE, 0.6, {"hp": 2000.0}),
			L(SINE, 0.02, 0.1, 200, 80, 0.5),
		], 0.5],
		"skill_tumble": [[
			L(NOISE, 0, 0.3, RATE, RATE, 0.7, {"shape": "swell", "lp": 600.0, "lp1": 1800.0, "hp": 200.0}),
			L(SINE, 0, 0.25, 120, 60, 0.3),
		], 0.4],
	}
	return sounds


func _render_sfx(layers: Array, level: float) -> PackedFloat32Array:
	var length := 0.0
	for layer: Array in layers:
		length = maxf(length, float(layer[1]) + float(layer[2]))
	var buffer := PackedFloat32Array()
	buffer.resize(int((length + 0.02) * RATE))
	rng.seed = hash(layers.size())
	for layer: Array in layers:
		_render_layer(buffer, layer)
	var peak := 0.0001
	for sample in buffer:
		peak = maxf(peak, absf(sample))
	for i in buffer.size():
		buffer[i] *= level / peak
	return buffer


func _render_layer(buffer: PackedFloat32Array, layer: Array) -> void:
	var wave: int = layer[0]
	var start := int(float(layer[1]) * RATE)
	var count := int(float(layer[2]) * RATE)
	var from_hz: float = layer[3]
	var ratio: float = float(layer[4]) / from_hz
	var volume: float = layer[5]
	var options: Dictionary = layer[6]
	var attack: float = options.get("a", 0.004)
	var shape: String = options.get("shape", "exp")
	var duty: float = options.get("duty", 0.5)
	var vibrato: float = options.get("vib", 0.0)
	var vibrato_rate: float = options.get("vib_rate", 8.0)
	var lowpass_from: float = options.get("lp", 0.0)
	var lowpass_ratio: float = float(options.get("lp1", lowpass_from)) / maxf(lowpass_from, 1.0)
	var highpass: float = options.get("hp", 0.0)
	var highpass_a := 1.0 - exp(-TAU * highpass / RATE)
	var tremolo: float = options.get("trem", 0.0)
	var tremolo_rate: float = options.get("trem_rate", 12.0)
	var phase := 0.0
	var noise_value := 0.0
	var low_state := 0.0
	var high_state := 0.0
	for k in count:
		var index := start + k
		if index >= buffer.size():
			break
		var t := float(k) / float(count)
		var seconds := float(k) / RATE
		var frequency := from_hz * pow(ratio, t)
		if vibrato > 0.0:
			frequency *= 1.0 + vibrato * sin(TAU * vibrato_rate * seconds)
		var last_phase := phase
		phase += frequency / RATE
		var sample: float
		if wave == NOISE:
			if floorf(phase) != floorf(last_phase):
				noise_value = rng.randf_range(-1.0, 1.0)
			sample = noise_value
		else:
			sample = _oscillator(wave, phase, duty)
		var envelope := minf(seconds / attack, 1.0)
		match shape:
			"exp":
				envelope *= exp(-5.0 * t)
			"lin":
				envelope *= 1.0 - t
			"flat":
				envelope *= minf((1.0 - t) * 12.0, 1.0)
			"swell":
				envelope *= sin(PI * t)
		if tremolo > 0.0:
			envelope *= 1.0 - tremolo * (0.5 + 0.5 * sin(TAU * tremolo_rate * seconds))
		if lowpass_from > 0.0:
			var cutoff := lowpass_from * pow(lowpass_ratio, t)
			low_state += (1.0 - exp(-TAU * cutoff / RATE)) * (sample - low_state)
			sample = low_state
		if highpass > 0.0:
			high_state += highpass_a * (sample - high_state)
			sample -= high_state
		buffer[index] += sample * envelope * volume


# --- Output -----------------------------------------------------------------------------------------


func _save(path: String, buffer: PackedFloat32Array) -> void:
	var data := PackedByteArray()
	data.resize(buffer.size() * 2)
	for i in buffer.size():
		data.encode_s16(i * 2, int(clampf(buffer[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	var error := stream.save_to_wav(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("Could not save %s: %s" % [path, error_string(error)])

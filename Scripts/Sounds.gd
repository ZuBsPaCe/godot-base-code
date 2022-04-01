extends Node2D


class SampleInfo:
	var key
	var samples := []
	var volumes := []

	func _init(p_key):
		key = p_key





var _sample_dict := {}

var _positional_players := []
var _center_players := []


# Add this class to the player node for Positional Audio!
func _ready() -> void:
	pass


func register(key, sample: AudioStreamSample, volume: float):
	var sample_info: SampleInfo = _sample_dict.get(key)

	if sample_info == null:
		sample_info = SampleInfo.new(key)
		_sample_dict[key] = sample_info

	sample_info.samples.push_back(sample)
	sample_info.volumes.push_back(-80.0 + volume)


func play(key, pos = null):
	var sample_info: SampleInfo = _sample_dict[key]
	var index := randi() % sample_info.samples.size()
	var stream: AudioStreamSample = sample_info.samples[index]
	var volume: float = sample_info.volumes[index]

	_play(stream, volume, pos)


func play_delayed(key, delay: float, play_while_paused: bool, pos = null):
	yield(get_tree().create_timer(delay, play_while_paused), "timeout")

	play(key, pos)


func _play(stream: AudioStreamSample, volume: float, pos = null) -> void:
	
	var pos_valid := typeof(pos) == TYPE_VECTOR2
	
	var players := _positional_players if pos_valid else _center_players

	var player: AudioStreamPlayer2D

	for existing_player in players:
		if !existing_player.playing:
			player = existing_player
			break

	if player == null && players.size() >= 20:
		return

	if player == null:
		player = AudioStreamPlayer2D.new()
		player.pause_mode = PAUSE_MODE_PROCESS

		if pos_valid:
			player.attenuation = 6.0

		player.bus = "Sounds"
		add_child(player)
		players.append(player)

	player.stream = stream
	player.volume_db = volume

	if pos_valid:
		var pos_vec:Vector2 = pos
		player.position = pos_vec - global_position
		player.pitch_scale = 0.95 + randf() * 0.1
#	else:
#		player_pos = Vector2(240, 135)

	player.play()

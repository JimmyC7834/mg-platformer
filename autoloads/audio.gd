extends Node

var stream_player: AudioStreamPlayer2D

func _ready() -> void:
    stream_player = AudioStreamPlayer2D.new()
    add_child(stream_player)

func play(stream: AudioStream, volumn: float = 0.0, pitch: float = 1.0):
    stream_player.stream = stream
    stream_player.volume_db = volumn
    stream_player.pitch_scale = pitch
    stream_player.play()

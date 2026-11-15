
extends Node

var music_player: AudioStreamPlayer

const MUSIC = preload("uid://b5vtk7pyb21fk")

func _ready() -> void:
	music_player = AudioStreamPlayer.new()

	music_player.stream = MUSIC
	music_player.volume_db = -12.0

	add_child(music_player)

	music_player.play()

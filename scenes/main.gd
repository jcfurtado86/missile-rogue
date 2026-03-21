extends Node

@onready var current_scene: Node = null

func _ready() -> void:
	var game_scene = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game_scene)
	current_scene = game_scene

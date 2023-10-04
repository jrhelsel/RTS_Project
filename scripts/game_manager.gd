extends Node3D

var players = {}

var fullscreen
signal fullscreen_toggled



func _ready():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		fullscreen = true
	else:
		fullscreen = false



func _input(event):
	if Input.is_action_just_pressed("toggle_fullscreen"):
		fullscreen_toggled.emit(fullscreen)
		if fullscreen:
			fullscreen = false
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			fullscreen = true
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)



func _process(delta):
	pass

extends Node

@onready var rts_camera = $RTSCameraRig/Camera3D
@onready var champion_camera = $player/camera_rig/Camera3D

@onready var transition_camera = $TransitionCamera

var current_camera: Camera3D
var transitioning = false



func _ready():
	#start scene on the rts camera
	rts_camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED



func _process(delta):
	if Input.is_action_just_pressed("toggle_camera"):
		if rts_camera.current:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			transition(rts_camera, champion_camera)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED
			transition(champion_camera, rts_camera)
	pass



func transition(from: Camera3D, to: Camera3D, duration: float = 1.0):
	if transitioning: return
	
	var tween = create_tween()
	
	transition_camera.fov = from.fov
	transition_camera.cull_mask = from.cull_mask
	
	transition_camera.global_transform = from.global_transform
	
	transition_camera.current = true
	transitioning = true
	
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(transition_camera, "global_transform", to.global_transform, duration).from(transition_camera.global_transform)
	tween.tween_property(transition_camera, "fov", to.fov, duration).from(transition_camera.fov)
	
	await tween.finished
	
	to.current = true
	transitioning = false

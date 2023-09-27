extends Node3D

@onready var rts_camera = $RTSCameraRig/Camera3D
@onready var champion_camera = $player/CameraRig/CameraSpring/Camera3D

@onready var transition_camera = $TransitionCamera

signal camera_changed(camera: Camera3D)
signal move_unit(target_position)

var champion_view
var rts_view

var transitioning = false



func _ready():
	#start scene on the rts camera
	champion_view = false
	rts_view = true
	rts_camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	


func _input(event):
	if Input.is_action_just_pressed("toggle_camera"):
		if rts_camera.current:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			transition(rts_camera, champion_camera)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED
			transition(champion_camera, rts_camera)
			
			
	if rts_camera.current && Input.is_action_just_pressed("right_mouse"):
		find_move_position()

func _process(delta):
	pass


func find_move_position():
	var mouse_position = get_viewport().get_mouse_position()
	var ray_length = 50;
	var from = rts_camera.project_ray_origin(mouse_position)
	var to = from + rts_camera.project_ray_normal(mouse_position) * ray_length
	var space = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	ray_query.collide_with_areas = true
	var result = space.intersect_ray(ray_query)
	
	emit_signal("move_unit", result.position)



func transition(from: Camera3D, to: Camera3D, duration: float = 1.0):
	if transitioning: return
	
	emit_signal("camera_changed", to)
	var tween = create_tween()
	
	transition_camera.fov = from.fov
	transition_camera.cull_mask = from.cull_mask
	
	transition_camera.global_transform = from.global_transform
	
	transition_camera.current = true
	transitioning = true
	
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(transition_camera, "transform", to.transform, duration).from(transition_camera.transform)
	tween.tween_property(transition_camera, "fov", to.fov, duration).from(transition_camera.fov)
	
	await tween.finished
	
	to.current = true
	transitioning = false


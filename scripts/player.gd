extends Node3D

@onready var champion_camera = $champion/CameraRig/CameraSpring/Camera3D
@onready var rts_camera = $RTSCameraRig/Camera3D
var transition_camera

var in_champion_view
var in_rts_view

var transitioning = false
var navigation_interrupted = false

var selected_units: Array[int] = [] #selected unit ID's

var unit_group: String = "unit" + str(name)
var next_unit_id: int = 1
var unit_count: int = 1

signal action_raycast_hit
signal camera_transition


func _ready():
	pass # Replace with function body.



func _input(event):
	if !$champion/MultiplayerSynchronizer.is_multiplayer_authority(): return

	#rts view inputs
	if in_rts_view:
		pass

	#inputs same for both views
	if Input.is_action_just_pressed("right_mouse"):
		var action = action_raycast()
		action_raycast_hit.emit(action)
	
	if Input.is_action_just_pressed("toggle_camera"):
		transition()
		
	if Input.is_action_just_pressed("spawn_unit"):
		spawn_unit.rpc()
	
	if Input.is_action_just_pressed("print_debug_message"):
		print("Unit group: " + unit_group)
		print("Unit count: " + str(unit_count))
		print(str(get_tree().get_nodes_in_group(unit_group)))
		print("")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func transition():
	#transitions the camera from the current view to the other
	if transitioning: return
	
	camera_transition.emit()
	
	if $champion/Visuals/mixamo_base/AnimationPlayer.current_animation != "idle":
		$champion/Visuals/mixamo_base/AnimationPlayer.play("idle")
		
	var target_camera: Camera3D
	var target_transform: Transform3D
	
	var champion_camera_transform_rel_to_player = $champion.transform * $champion/CameraRig.transform * $champion/CameraRig/CameraSpring.transform * champion_camera.transform
	var rts_camera_transform_rel_to_player = $RTSCameraRig.transform * rts_camera.transform
	
	if in_champion_view: #going from champion view to rts view
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		in_champion_view = false
		in_rts_view = true
		
		target_camera = rts_camera
		transition_camera = $RTSCameraRig/Camera3D/ToRTSTransitionCamera
		
		target_transform = transition_camera.transform
		transition_camera.transform = rts_camera_transform_rel_to_player.affine_inverse() * champion_camera_transform_rel_to_player
		
	else: #going from rts view to champion view
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		in_champion_view = true
		in_rts_view = false
		
		target_camera = champion_camera
		transition_camera = $champion/CameraRig/CameraSpring/Camera3D/ToChampionTransitionCamera
		
		target_transform = transition_camera.transform
		transition_camera.transform = champion_camera_transform_rel_to_player.affine_inverse() * rts_camera_transform_rel_to_player
	
	transition_camera.current = true
	transitioning = true
	
	var tween = create_tween()
	
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(transition_camera, "transform", target_transform, 1.0).from(transition_camera.transform)
	
	await tween.finished #code resumes at this point when the tween has finished (like a thread, but not quite)
	
	target_camera.current = true
	transitioning = false


func action_raycast():
	#casts a ray from the appropriate perspective and returns it
	var current_camera: Camera3D
	var cast_position = get_viewport().get_mouse_position()
	
	if transitioning:
		current_camera = transition_camera
	elif in_champion_view:
		current_camera = champion_camera
		cast_position = get_viewport().content_scale_size / 2
	else:
		current_camera = rts_camera
	
	var from = current_camera.project_ray_origin(cast_position)
	var to = from + current_camera.project_ray_normal(cast_position) * 100 #ray length
	var space = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	ray_query.collide_with_areas = true
	var result = space.intersect_ray(ray_query)
	
	return result

@rpc("any_peer", "call_local")
func spawn_unit():
	var new_unit = preload("res://scenes/unit.tscn").instantiate()
	add_child(new_unit)
	new_unit.position = position + Vector3(2, 1, 2)
	new_unit.add_to_group(unit_group)
	new_unit.set_id(next_unit_id)
	
	next_unit_id += 1
	unit_count += 1
	

func remove_unit(id):
	for unit in get_tree().get_nodes_in_group(unit_group):
		if unit.get_id == id:
			unit.queue_free()

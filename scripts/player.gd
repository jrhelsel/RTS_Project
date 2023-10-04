extends Node3D

@onready var selection_box = $RTSCameraRig/Camera3D/SelectionBox

@onready var champion_camera = $Champion/CameraRig/CameraSpring/Camera3D
@onready var rts_camera = $RTSCameraRig/Camera3D
var transition_camera

var in_champion_view
var in_rts_view

var transitioning = false
var navigation_interrupted = false

#group names
var selected_units_group: String
var unit_group: String

var control_group_1: String
var control_group_2: String
var control_group_3: String
var control_group_4: String
var control_group_5: String
var control_group_6: String
var control_group_7: String
var control_group_8: String
var control_group_9: String




var next_unit_id: int = 1
var unit_count: int = 1

var box_selection_start_position: Vector2
var mouse_position: Vector2

signal action_raycast_hit
signal camera_transition

const DEFAULT_COLLISION_MASK = 0xFFFFFFFF
const TERRAIN_COLLISION_MASK = 0x2
const UNIT_COLLISION_MASK = 0x4



func _ready():
	in_rts_view = true

	GameManager.fullscreen_toggled.connect(_on_fullscreen_toggle)
	if GameManager.fullscreen:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	
	selected_units_group = "selected_units" + name
	unit_group = "units" + name
	
	control_group_1 = "cg1" + name
	control_group_2 = "cg2" + name
	control_group_3 = "cg3" + name
	control_group_4 = "cg4" + name
	control_group_5 = "cg5" + name
	control_group_6 = "cg6" + name
	control_group_7 = "cg7" + name
	control_group_8 = "cg8" + name
	control_group_9 = "cg9" + name



	$RTSCameraRig.position.x = lerp($RTSCameraRig.position.x, $Champion.position.x, 1)
	$RTSCameraRig.position.z = lerp($RTSCameraRig.position.z, $Champion.position.z + 5, 1)


func _input(event):
	if !$Champion/MultiplayerSynchronizer.is_multiplayer_authority(): return

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




	#control groups
	if Input.is_action_just_pressed("control_group_1"):
		if Input.is_action_pressed("left_control"):
			set_control_group(control_group_1)
		else:
			select_control_group(control_group_1)

	if Input.is_action_just_pressed("control_group_2"):
		if Input.is_action_pressed("left_control"):
			set_control_group(control_group_2)
		else:
			select_control_group(control_group_2)
			
	if Input.is_action_just_pressed("control_group_3"):
		if Input.is_action_pressed("left_control"):
			set_control_group(control_group_3)
		else:
			select_control_group(control_group_3)
			
	if Input.is_action_just_pressed("control_group_4"):
		if Input.is_action_pressed("left_control"):
			set_control_group(control_group_4)
		else:
			select_control_group(control_group_4)
			
	if Input.is_action_just_pressed("control_group_5"):
		if Input.is_action_pressed("left_control"):
			set_control_group(control_group_5)
		else:
			select_control_group(control_group_5)
			
	if Input.is_action_just_pressed("control_group_6"):
		if Input.is_action_pressed("left_control"):
			set_control_group(control_group_6)
		else:
			select_control_group(control_group_6)
			
	if Input.is_action_just_pressed("control_group_7"):
		if Input.is_action_pressed("left_control"):
			set_control_group(control_group_7)
		else:
			select_control_group(control_group_7)
			
	if Input.is_action_just_pressed("control_group_8"):
		if Input.is_action_pressed("left_control"):
			set_control_group(control_group_8)
		else:
			select_control_group(control_group_8)
			
	if Input.is_action_just_pressed("control_group_9"):
		if Input.is_action_pressed("left_control"):
			set_control_group(control_group_9)
		else:
			select_control_group(control_group_9)



	if Input.is_action_just_pressed("print_debug_message"):
		print("Unit group: " + unit_group)
		print("Unit count: " + str(unit_count))
		print(str(get_tree().get_nodes_in_group(unit_group)))
		print("")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if in_rts_view:
		mouse_position  = get_viewport().get_mouse_position()
		
		if Input.is_action_just_pressed("left_mouse"):
			box_selection_start_position = mouse_position
			selection_box.start_position = box_selection_start_position
			selection_box.is_visible = true
		
		if Input.is_action_pressed("left_mouse"):
			selection_box.end_position = mouse_position
		
		if Input.is_action_just_released("left_mouse"):
			selection_box.end_position = mouse_position
			selection_box.is_visible = false
			unit_selection(box_selection_start_position, mouse_position)
		
		
		if Input.is_action_pressed("focus_champion"):
			if Input.is_action_just_pressed("focus_champion"):
				$RTSCameraRig.reset_zoom()
			$RTSCameraRig.position.x = lerp($RTSCameraRig.position.x, $Champion.position.x, 1)
			$RTSCameraRig.position.z = lerp($RTSCameraRig.position.z, $Champion.position.z + 5, 1)


func transition():
	#transitions the camera from the current view to the other
	if transitioning: return
	
	camera_transition.emit()
	
	if $Champion/Visuals/mixamo_base/AnimationPlayer.current_animation != "idle":
		$Champion/Visuals/mixamo_base/AnimationPlayer.play("idle")
		
	var target_camera: Camera3D
	var target_transform: Transform3D
	
	var champion_camera_transform_rel_to_player = $Champion.transform * $Champion/CameraRig.transform * $Champion/CameraRig/CameraSpring.transform * champion_camera.transform
	var rts_camera_transform_rel_to_player = $RTSCameraRig.transform * rts_camera.transform
	
	if in_champion_view: #going from champion view to rts view
		if GameManager.fullscreen:
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED
		else:
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
		transition_camera = $Champion/CameraRig/CameraSpring/Camera3D/ToChampionTransitionCamera
		
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


func action_raycast(collision_mask: int = DEFAULT_COLLISION_MASK):
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
	ray_query.collision_mask = collision_mask
	var result = space.intersect_ray(ray_query)
	
	return result



func unit_selection(box_start, box_end):
	if !Input.is_action_pressed("shift"):
		for node in get_tree().get_nodes_in_group(selected_units_group):
			node.remove_from_group(selected_units_group)
	
	if box_start.distance_squared_to(box_end) < 64:
		var selection = action_raycast(UNIT_COLLISION_MASK)
		if !selection.is_empty():
			selection.get("collider").add_to_group(selected_units_group)
		
		print("single unit selection: ")

	else:
		selection_box.set_selection_area()
		for unit in get_tree().get_nodes_in_group(unit_group):
			if selection_box.selection_area.has_point(rts_camera.unproject_position(unit.global_transform.origin)):
				unit.add_to_group(selected_units_group)
		
		print("box unit selection: ")
	print(str(get_tree().get_nodes_in_group(selected_units_group)))


func set_control_group(group):
	for unit in get_tree().get_nodes_in_group(group):
		unit.remove_from_group(group)
		
	for unit in get_tree().get_nodes_in_group(selected_units_group):
		unit.add_to_group(group)

func select_control_group(group):
	for unit in get_tree().get_nodes_in_group(selected_units_group):
		unit.remove_from_group(selected_units_group)

	for unit in get_tree().get_nodes_in_group(group):
		unit.add_to_group(selected_units_group)

@rpc("any_peer", "call_local")
func spawn_unit():
	var new_unit = preload("res://scenes/unit.tscn").instantiate()
	add_child(new_unit)
	new_unit.position = position + Vector3(0, 1, next_unit_id)
	new_unit.add_to_group(unit_group)
	new_unit.set_id(next_unit_id)
	
	next_unit_id += 1
	unit_count += 1
	


func remove_unit(id):
	for unit in get_tree().get_nodes_in_group(unit_group):
		if unit.get_id == id:
			unit.queue_free()

func _on_fullscreen_toggle(fullscreen):
	if in_rts_view:
		if fullscreen:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED

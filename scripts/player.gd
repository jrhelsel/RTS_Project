extends CharacterBody3D

@onready var camera_rig = $CameraRig
@onready var camera_spring = $CameraRig/CameraSpring

@onready var animation_player = $Visuals/mixamo_base/AnimationPlayer
@onready var visuals = $Visuals
@onready var navigation_agent_3d = $NavigationAgent3D

@onready var rts_camera = $"../RTSCameraRig/Camera3D"
@onready var champion_camera = $CameraRig/CameraSpring/Camera3D
@onready var transition_camera = $TransitionCamera

@export var sensitivity_horizontal = 0.15
@export var sensitivity_vertical = 0.08

var in_champion_view
var in_rts_view

var transitioning = false

var SPEED = 4.2
const JUMP_VELOCITY = 4.5

var navigation_interrupted = false

var multiplayer_authorized = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	$MultiplayerSynchronizer.set_multiplayer_authority(str($"..".name).to_int())
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		
		multiplayer_authorized = true
		
		print($"..".name)
		print("Authorized:")
		print(multiplayer_authorized)

		in_champion_view = false
		in_rts_view = true
		rts_camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		animation_player.play("idle")



func _input(event):
	if multiplayer_authorized:
		#champion camera is active
		if in_champion_view:
			#camera rotation
			if event is InputEventMouseMotion:
				rotation.y -= deg_to_rad(event.relative.x * sensitivity_horizontal) 
				visuals.rotation.y += deg_to_rad(event.relative.x * sensitivity_horizontal)
				if !transitioning:
					var vertical_rotation = camera_rig.rotation.x - deg_to_rad(event.relative.y * sensitivity_vertical)
					vertical_rotation = clamp(vertical_rotation, -1.1, 0.35)
					camera_rig.rotation.x = vertical_rotation
			
			if Input.get_vector("left", "right", "forward", "backward"):
				navigation_agent_3d.set_target_position(position)
				navigation_interrupted = true


		if Input.is_action_just_pressed("right_mouse"):
			var action = action_raycast()
			handle_action(action)
		
		if Input.is_action_just_pressed("toggle_camera"):
			transition()
	



func _physics_process(delta):
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	move_and_slide()
	
	if multiplayer_authorized:
		if in_champion_view:
			if navigation_interrupted:
				champion_movement(delta)
			else:
				rts_movement(delta)
				
		else:
			rts_movement(delta)





func champion_movement(delta):
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if animation_player.current_animation != "running":
			animation_player.play("running")
		
		visuals.rotation.y = lerp_angle(visuals.rotation.y, atan2(-direction.x, -direction.z) - rotation.y, 10.0 * delta)
		
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
	else:
		if animation_player.current_animation != "idle":
			animation_player.play("idle")
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func rts_movement(delta):
	if navigation_agent_3d.is_navigation_finished():
		velocity = Vector3(0,0,0) #dirty fix TODO
		return
	
	var target_position = navigation_agent_3d.get_next_path_position()
	var direction = global_position.direction_to(target_position)
	
	velocity = direction * SPEED
	
	visuals.rotation.y = lerp_angle(visuals.rotation.y, atan2(-direction.x, -direction.z) - rotation.y, 12.0 * delta)
		
	if navigation_agent_3d.distance_to_target() > 0.2:
		if animation_player.current_animation != "running":
			animation_player.play("running")
			
	else:
		if animation_player.current_animation != "idle":
			animation_player.play("idle")

func transition():
	#transitions the camera from the current view to the other
	if transitioning: return
	
	if animation_player.current_animation != "idle":
		animation_player.play("idle")
		
	var target_camera: Camera3D
	var target_transform
	
	var champion_camera_transform_rel_to_player = camera_rig.transform * camera_spring.transform * champion_camera.transform
	var rts_camera_transform_rel_to_player = transform.affine_inverse() * rts_camera.global_transform
	
	if in_champion_view:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		in_champion_view = false
		in_rts_view = true
		target_camera = rts_camera
		
		transition_camera.transform = champion_camera_transform_rel_to_player
		target_transform = rts_camera_transform_rel_to_player
		
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		in_champion_view = true
		in_rts_view = false
		target_camera = champion_camera
		
		transition_camera.transform = rts_camera_transform_rel_to_player #WORKS
		target_transform = champion_camera_transform_rel_to_player
	
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
	#print(result) #debug
	
	return result

func handle_action(action):
	#for now this just handles walking to a target location. actions in the future will include clicking resource nodes, enemies, etc.
	navigation_agent_3d.set_target_position(action.position)
	navigation_interrupted = false

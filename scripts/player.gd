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

var SPEED = 2.5
const JUMP_VELOCITY = 4.5

var walking_speed = 1.8
var running_speed = 4.2
var running = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")



func _ready():
	in_champion_view = false
	in_rts_view = true
	rts_camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	animation_player.play("idle")
	pass



func _input(event):
	#champion camera is active
	if in_champion_view:
		if event is InputEventMouseMotion:
			rotation.y -= deg_to_rad(event.relative.x * sensitivity_horizontal) 
			var vertical_rotation = camera_rig.rotation.x - deg_to_rad(event.relative.y * sensitivity_vertical)
			vertical_rotation = clamp(vertical_rotation, -1.1, 0.35)
			camera_rig.rotation.x = vertical_rotation
			
	#rts camera is active
	else: 
		if Input.is_action_just_pressed("right_mouse"):
			var mouse_position = get_viewport().get_mouse_position()
			var ray_length = 100;
			var from = rts_camera.project_ray_origin(mouse_position)
			var to = from + rts_camera.project_ray_normal(mouse_position) * ray_length
			var space = get_world_3d().direct_space_state
			var ray_query = PhysicsRayQueryParameters3D.new()
			ray_query.from = from
			ray_query.to = to
			ray_query.collide_with_areas = true
			var result = space.intersect_ray(ray_query)
			#print(result)
			
			navigation_agent_3d.set_target_position(result.position)
	
	if Input.is_action_just_pressed("toggle_camera"):
		transition()
	



func _physics_process(delta):
	
	#------------------------
	# champion input control
	#------------------------
	if in_champion_view:
		if Input.is_action_pressed("run"):
			SPEED = running_speed
			running = true
		else:
			SPEED = walking_speed
			running = false

		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		var input_dir = Input.get_vector("left", "right", "forward", "backward")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			if running:
				if animation_player.current_animation != "running":
					animation_player.play("running")
			else:
				if animation_player.current_animation != "walking":
					animation_player.play("walking")
					
			visuals.rotation.y = lerp_angle(visuals.rotation.y, atan2(-direction.x, -direction.z) - rotation.y, 10.0 * delta)
			
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			
		else:
			if animation_player.current_animation != "idle":
				animation_player.play("idle")
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
			
	#------------------
	# rts input control
	#------------------
	else:
		if navigation_agent_3d.is_navigation_finished():
			return
		
		var target_position = navigation_agent_3d.get_next_path_position()
		var direction = global_position.direction_to(target_position)
	
		SPEED = running_speed
	
		velocity = direction * SPEED
		
		visuals.rotation.y = lerp_angle(visuals.rotation.y, atan2(-direction.x, -direction.z) - rotation.y, 12.0 * delta)
			
		if navigation_agent_3d.distance_to_target() > 0.2:
			if animation_player.current_animation != "running":
				animation_player.play("running")
				
		else:
			if animation_player.current_animation != "idle":
				animation_player.play("idle")

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	move_and_slide()



func transition():
	if transitioning: return
	
	navigation_agent_3d.set_target_position(position)
	if animation_player.current_animation != "idle":
		animation_player.play("idle")
		
	var target_camera: Camera3D
	var target_transform
	
	var champion_camera_transform_rel_to_player = camera_rig.transform * camera_spring.transform * champion_camera.transform
	var rts_camera_transform_rel_to_player = transform.affine_inverse() * rts_camera.global_transform
	
	if in_champion_view:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED
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
	
	await tween.finished
	
	target_camera.current = true
	transitioning = false


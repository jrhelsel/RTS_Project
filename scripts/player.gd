extends CharacterBody3D

@onready var camera_rig = $CameraRig
@onready var animation_player = $Visuals/mixamo_base/AnimationPlayer
@onready var visuals = $Visuals
@onready var navigation_agent_3d = $NavigationAgent3D

@onready var rts_camera = $"../RTSCameraRig/Camera3D"

@export var sensitivity_horizontal = 0.15
@export var sensitivity_vertical = 0.08

signal single_unit_selected(unit)

var SPEED = 2.5
const JUMP_VELOCITY = 4.5

var in_champion_view = false
var in_rts_view = true

var walking_speed = 1.8
var running_speed = 4.2
var running = false

var selected = false



# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	animation_player.play("idle")
	pass
	
	
func _input(event):
	
	#champion camera is active
	if in_champion_view:
		if event is InputEventMouseMotion:
			#rotate_y(deg_to_rad(-event.relative.x * sensitivity_horizontal))
			#camera_rig.rotate_x(deg_to_rad(-event.relative.y * sensitivity_vertical))
			
			rotation.y -= deg_to_rad(event.relative.x * sensitivity_horizontal) 
			var vertical_rotation = camera_rig.rotation.x - deg_to_rad(event.relative.y * sensitivity_vertical)
			vertical_rotation = clamp(vertical_rotation, -1.1, 0.35)
			camera_rig.rotation.x = vertical_rotation
			
	#rts camera is active

			

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
	#print(navigation_agent_3d.distance_to_target())


#for now, the champion must stand still between camera transitions. in the future the champion should move fluidly between transistions
func _on_camera_changed(camera):
	if rts_camera == camera:
		in_rts_view = true
		in_champion_view = false
	else:
		in_rts_view = false
		in_champion_view = true
	
	navigation_agent_3d.set_target_position(position)
	if animation_player.current_animation != "idle":
		animation_player.play("idle")



func _on_move_unit(target_position):
	navigation_agent_3d.set_target_position(target_position)

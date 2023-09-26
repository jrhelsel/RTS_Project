extends CharacterBody3D

@onready var camera_rig = $camera_rig
@onready var animation_player = $visuals/mixamo_base/AnimationPlayer
@onready var visuals = $visuals

@onready var rts_camera = $"../RTSCameraRig/Camera3D"

@onready var navigation_agent_3d = $NavigationAgent3D

var SPEED = 2.5
const JUMP_VELOCITY = 4.5

var walking_speed = 1.8
var running_speed = 4.2

var running = false

@export var sensitivity_horizontal = 0.15
@export var sensitivity_vertical = 0.08

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	animation_player.play("idle")
	pass
	
	
func _input(event):
	
	#champion camera is active
	if $camera_rig/Camera3D.current:
		if event is InputEventMouseMotion:
			rotate_y(deg_to_rad(-event.relative.x * sensitivity_horizontal))
			camera_rig.rotate_x(deg_to_rad(-event.relative.y * sensitivity_vertical))
			
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
			print(result)
			
			navigation_agent_3d.set_target_position(result.position)
			

func _physics_process(delta):
	
	#champion input control
	if $camera_rig/Camera3D.current: #if in champion perspective, use champion controls
		if Input.is_action_pressed("run"):
			SPEED = running_speed
			running = true
		else:
			SPEED = walking_speed
			running = false

		# Handle Jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir = Input.get_vector("left", "right", "forward", "backward")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			if running:
				if animation_player.current_animation != "running":
					animation_player.play("running")
			else:
				if animation_player.current_animation != "walking":
					animation_player.play("walking")
					
			var movement_direction = position + direction
			visuals.rotation.y = lerp_angle(visuals.rotation.y, atan2(-direction.x, -direction.z) - rotation.y, 0.2)
			
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			if animation_player.current_animation != "idle":
				animation_player.play("idle")
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
			
			
	#rts input control
	else:
		if navigation_agent_3d.is_navigation_finished():
			return
		
		var target_position = navigation_agent_3d.get_next_path_position()
		var direction = global_position.direction_to(target_position)
	
		velocity = direction * SPEED


	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	move_and_slide()

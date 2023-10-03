extends CharacterBody3D


#node references
@onready var animation_player = $Visuals/mixamo_base/AnimationPlayer
@onready var visuals = $Visuals
@onready var navigation_agent_3d = $NavigationAgent3D

@onready var rts_camera = $"../RTSCameraRig/Camera3D"
@onready var champion_camera = $CameraRig/CameraSpring/Camera3D



#configurable values
@export var sensitivity_horizontal = 0.15
@export var sensitivity_vertical = 0.08

var SPEED = 4.2
const JUMP_VELOCITY = 4.5



#state and function variables
var transition_camera: Camera3D

var in_champion_view
var in_rts_view

var transitioning = false
var navigation_interrupted = false



# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")



func _enter_tree():
	$MultiplayerSynchronizer.set_multiplayer_authority(str($"..".name).to_int())

func _ready():
	if !$MultiplayerSynchronizer.is_multiplayer_authority(): return

	in_champion_view = false
	in_rts_view = true
	rts_camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	animation_player.play("idle")



func _input(event):
	if !$MultiplayerSynchronizer.is_multiplayer_authority(): return
	
	#champion view inputs
	if in_champion_view:
		#camera rotation
		if event is InputEventMouseMotion:
			rotation.y -= deg_to_rad(event.relative.x * sensitivity_horizontal)
			visuals.rotation.y += deg_to_rad(event.relative.x * sensitivity_horizontal)
			if !transitioning:
				var vertical_rotation = $CameraRig.rotation.x - deg_to_rad(event.relative.y * sensitivity_vertical)
				vertical_rotation = clamp(vertical_rotation, -1.1, 0.35)
				$CameraRig.rotation.x = vertical_rotation
		
		if Input.get_vector("left", "right", "forward", "backward"):
			navigation_agent_3d.set_target_position(position)
			navigation_interrupted = true
			
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY



func _physics_process(delta):
	if !$MultiplayerSynchronizer.is_multiplayer_authority(): return

	if in_champion_view:
		if navigation_interrupted:
			champion_movement(delta)
		else:
			rts_movement(delta)
		
	else: #in_rts_view
		if !navigation_interrupted:
			rts_movement(delta)
		
			# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	move_and_slide()





func champion_movement(delta):
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
		velocity = Vector3(0,velocity.y,0) #dirty fix TODO
		if animation_player.current_animation != "idle":
			animation_player.play("idle")
		return
	
	if animation_player.current_animation != "running":
		animation_player.play("running")
		
	var target_position = navigation_agent_3d.get_next_path_position()
	var direction = global_position.direction_to(target_position)
	
	velocity = direction * SPEED
	
	visuals.rotation.y = lerp_angle(visuals.rotation.y, atan2(-direction.x, -direction.z) - rotation.y, 12.0 * delta)

func handle_action(action):
	#for now this just handles walking to a target location. actions in the future will include clicking resource nodes, enemies, etc.
	navigation_agent_3d.set_target_position(action.position)
	navigation_interrupted = false


func _on_action_raycast_hit(action):
	handle_action(action)


func _on_camera_transition():
	if in_champion_view:
		in_champion_view = false
		in_rts_view = true
	else:
		in_champion_view = true
		in_rts_view = false
		
	if navigation_interrupted:
		velocity = Vector3(0,velocity.y,0)
	

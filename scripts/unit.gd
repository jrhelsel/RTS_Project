extends CharacterBody3D

@onready var animation_player = $Visuals/mixamo_base/AnimationPlayer
@onready var visuals = $Visuals
@onready var navigation_agent_3d = $NavigationAgent3D

var SPEED = 4.2
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta):
	
	rts_movement(delta)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	move_and_slide()


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

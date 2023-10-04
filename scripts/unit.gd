extends CharacterBody3D

@onready var animation_player = $Visuals/mixamo_base/AnimationPlayer
@onready var visuals = $Visuals
@onready var navigation_agent_3d = $NavigationAgent3D

var SPEED = 4.2
const JUMP_VELOCITY = 4.5

var selected_units_group: String
var unit_group: String

var unit_id: int

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")



func _enter_tree():
	$MultiplayerSynchronizer.set_multiplayer_authority(str($"..".name).to_int())

func _ready():
	$"..".action_raycast_hit.connect(_on_action_raycast_hit)
	
	selected_units_group = "selected_units" + $"..".name
	unit_group = "units" + $"..".name
	
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

#for now this just handles walking to a target location. actions in the future will include clicking resource nodes, enemies, etc.
func handle_action(action):
	if action.is_empty() or !is_in_group(selected_units_group): return
	
	navigation_agent_3d.set_target_position(action.position)

func set_id(id):
	unit_id = id

func get_id():
	return unit_id


#signal response functions

func _on_action_raycast_hit(action):
	handle_action(action)


func _on_navigation_agent_3d_velocity_computed(_safe_velocity):
	pass # Replace with function body.

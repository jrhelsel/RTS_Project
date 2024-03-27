extends CharacterBody3D

@onready var animation_player = $Visuals/mixamo_base/AnimationPlayer
@onready var visuals = $Visuals
@onready var navigation_agent = $NavigationPathFollower/NavigationAgent3D
@onready var nav_path_follower = $NavigationPathFollower

@onready var outline_shader_surface = $Visuals/mixamo_base/Armature/Skeleton3D/Beta_Surface.get_active_material(0).next_pass
@onready var outline_shader_joints = $Visuals/mixamo_base/Armature/Skeleton3D/Beta_Joints.get_active_material(0).next_pass

var SPEED = 4.2

var selected_units_group: String
var unit_group: String

var sync_position: Vector3
var sync_rotation

var unit_id: int

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")



func _enter_tree():
	$MultiplayerSynchronizer.set_multiplayer_authority(str($"..".name).to_int())

func _ready():
	if $MultiplayerSynchronizer.is_multiplayer_authority():
		
		$"..".action_raycast_hit.connect(_on_action_raycast_hit)
		$"..".selected_units_updated.connect(_on_selected_units_updated)
		
		selected_units_group = "selected_units" + $"..".name
		unit_group = "units" + $"..".name
		
	else:
		
		sync_position = global_position
		sync_rotation = global_rotation.y

func _physics_process(delta):
	if $MultiplayerSynchronizer.is_multiplayer_authority():
	
		rts_movement(delta)
		
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta
		
		sync_position = global_position
		sync_rotation = global_rotation.y
		
		move_and_slide()
		
	else:
		global_position = global_position.lerp(sync_position, .5)
		global_rotation.y = lerp_angle(global_rotation.y, sync_rotation, .5)

func rts_movement(delta):
	if navigation_agent.is_navigation_finished():
		velocity = Vector3(0,velocity.y,0)
		if animation_player.current_animation != "idle":
			animation_player.play("idle")
		return
	
	if animation_player.current_animation != "running":
		animation_player.play("running")
		
	var target_position = navigation_agent.get_next_path_position()
	var target_direction = global_position.direction_to(target_position)
	var unit_direction = Vector3(target_direction.x, 0, target_direction.z).normalized()
	
	var new_velocity = Vector3(unit_direction.x * SPEED, velocity.y, unit_direction.z * SPEED)
	nav_path_follower.global_position.y = target_position.y
	#velocity.x = unit_direction.x * SPEED
	#velocity.z = unit_direction.z * SPEED
	
	navigation_agent.set_velocity(new_velocity)
	
	visuals.rotation.y = lerp_angle(visuals.rotation.y, atan2(-unit_direction.x, -unit_direction.z) - rotation.y, 12.0 * delta)

#for now this just handles walking to a target location. actions in the future will include clicking resource nodes, enemies, etc.
func handle_action(action):
	if action.is_empty() or !is_in_group(selected_units_group): return
	
	#navigation_agent.set_target_position(action.position)

func set_id(id):
	unit_id = id

func get_id():
	return unit_id


#signal response functions

func _on_action_raycast_hit(action):
	handle_action(action)

func _on_selected_units_updated():
	if is_in_group(selected_units_group): 
		outline_shader_surface.set_shader_parameter("outline_enabled", true)
		outline_shader_joints.set_shader_parameter("outline_enabled", true)
		#print("unit oultines ON")
	else:
		outline_shader_surface.set_shader_parameter("outline_enabled", false)
		outline_shader_joints.set_shader_parameter("outline_enabled", false)
		#print("unit oultines OFF")



func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z


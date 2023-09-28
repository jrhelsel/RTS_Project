extends Node3D

@export var pan_speed = 30.0

var zooming = false

func _ready():
	pass



func _process(delta):
	if $Camera3D.current:
		var viewport_size = get_viewport().size
		var mouse_pos = get_viewport().get_mouse_position()
		var confined = Input.mouse_mode == Input.MOUSE_MODE_CONFINED
		
		if Input.is_action_pressed("pan_left") or (mouse_pos.x < 10 and confined):
			position.x -= pan_speed * delta
		elif Input.is_action_pressed("pan_right") or (mouse_pos.x > viewport_size.x - 10 and confined):
			position.x += pan_speed * delta
		if Input.is_action_pressed("pan_up") or (mouse_pos.y < 10 and confined):
			position.z -= pan_speed * delta
		elif Input.is_action_pressed("pan_down") or (mouse_pos.y > viewport_size.y - 10 and confined):
			position.z += pan_speed * delta
		
		
		#---------
		# zooming
		#---------
		var target_position = $Camera3D.position
		
		if Input.is_action_just_released("mouse_wheel_up") && $Camera3D.position.y >= 5.0:
			target_position = $Camera3D.position - $Camera3D.global_transform.basis.z
			
		if Input.is_action_just_released("mouse_wheel_down") && $Camera3D.position.y <= 20.0:
			target_position = $Camera3D.position + $Camera3D.global_transform.basis.z
			
		$Camera3D.position = $Camera3D.position.lerp(target_position, 200.0 * delta)


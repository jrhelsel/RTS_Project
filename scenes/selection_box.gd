extends Control

var is_visible = false
var mouse_position = Vector2()
var box_start_position = Vector2()
const box_outline_color = Color(0,1,0)
const box_outline_width = 3

func _draw():
	var start_box_threshold = box_start_position - mouse_position
	if is_visible and start_box_threshold.length() < 1:
		draw_line(box_start_position, Vector2(mouse_position.x, box_start_position.y), box_outline_color, box_outline_width)
		draw_line(box_start_position, Vector2(box_start_position.x, mouse_position.y), box_outline_color, box_outline_width)
		draw_line(mouse_position, Vector2(mouse_position.x, box_start_position.y), box_outline_color, box_outline_width)
		draw_line(mouse_position, Vector2(box_start_position.x, mouse_position.y), box_outline_color, box_outline_width)

func _process(delta):
	pass

extends Control

var is_visible = false
var end_position = Vector2()
var start_position = Vector2()
var selection_box_color = Color(1,1,1)
var selection_box_width = 2

var selection_area: Rect2

func _draw():
	if is_visible and start_position != end_position:
		draw_line(start_position, Vector2(end_position.x, start_position.y), selection_box_color, selection_box_width)
		draw_line(start_position, Vector2(start_position.x, end_position.y), selection_box_color, selection_box_width)
		draw_line(end_position, Vector2(end_position.x, start_position.y), selection_box_color, selection_box_width)
		draw_line(end_position, Vector2(start_position.x, end_position.y), selection_box_color, selection_box_width)

func _process(delta):
	queue_redraw()

func set_selection_area():
	if start_position.x > end_position.x:
		var temp = start_position.x
		start_position.x = end_position.x
		end_position.x = temp
	if start_position.y > end_position.y:
		var temp = start_position.y
		start_position.y = end_position.y
		end_position.y = temp
	selection_area = Rect2(start_position, end_position - start_position)


func set_start_position(start):
	start_position = start
	
func set_end_position(end):
	end_position = end
	
func set_visibility(visibility):
	is_visible = visibility

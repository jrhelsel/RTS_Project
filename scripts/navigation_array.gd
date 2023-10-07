extends Node3D

var cell_count: int = 0

var cell_spacing: float =  1.0

var lead_cell: cell
var cells: Array[cell]

enum Formation {RECTANGLE}



func _ready():
	pass

func _process(delta):
	pass

func update_selected_units():
	for unit in get_tree().get_nodes_in_group($"..".selected_units_group):
		cells.append(cell.new())
		cells[cell_count].unit = unit
		#print("adding " + str(unit) + " to nav array")
		cell_count += 1
	lead_cell = cells[0]
	#print(str(cell_count) + " total units")
	global_position = lead_cell.unit.global_position
	
	build_formation(Formation.RECTANGLE)

func build_formation(formation: Formation):
	if cell_count <= 1: return
	
	match formation:
		Formation.RECTANGLE: #general form for now is ~= 2x1 rectangle
			var rect_width: int = int(ceil(float(cell_count) / 2.0)) #stinky, might want to rework this conversion
			var rect_depth: int = int(ceil(cell_count / float(rect_width)))
			var grid_pointer: Vector2 = Vector2(0, 0)
			var entry_index: int = 0
			var neighbor_position: int = 0
			
			for entry in cells:
				
				grid_pointer.x = entry_index % rect_width
				grid_pointer.y = entry_index / rect_width
				
				entry.formation_position = grid_pointer * cell_spacing
				
				#top row
				if grid_pointer.y == 0:
					if grid_pointer.x == 0:
						#top left cell
						neighbor_position = entry_index + 1
						if neighbor_position <= cell_count - 1:
							entry.right = cells[neighbor_position]
						neighbor_position = entry_index + rect_width
						if neighbor_position <= cell_count - 1:
							entry.down = cells[neighbor_position]
					elif grid_pointer.x == rect_width - 1:
						#top right cell
						entry.left = cells[entry_index - 1]
						neighbor_position = entry_index + rect_width
						if neighbor_position <= cell_count - 1:
							entry.down = cells[neighbor_position]
					else:
						#rest of top row
						entry.left = cells[entry_index - 1]
						neighbor_position = entry_index + 1
						if neighbor_position <= cell_count - 1:
							entry.right = cells[neighbor_position]
						neighbor_position = entry_index + rect_width
						if neighbor_position <= cell_count - 1:
							entry.down = cells[neighbor_position]
					
				#bottom row
				elif grid_pointer.y == rect_depth - 1:
					if grid_pointer.x == 0:
						#bottom left cell
						entry.up = cells[entry_index - rect_width]
						neighbor_position = entry_index + 1
						if neighbor_position <= cell_count - 1:
							entry.right = cells[neighbor_position]
					elif grid_pointer.x == rect_width - 1: 
						#bottom right cell
						entry.up = cells[entry_index - rect_width]
						entry.left = cells[entry_index - 1]
					else:
						#rest of bottom row
						entry.up = cells[entry_index - rect_width]
						entry.left = cells[entry_index - 1]
						neighbor_position = entry_index + 1
						if neighbor_position <= cell_count - 1:
							entry.right = cells[neighbor_position]
						pass
						
				#rows between top and bottom
				else:
					if grid_pointer.x == 0:
						#left edge of grid
						entry.up = cells[entry_index - rect_width]
						neighbor_position = entry_index + 1
						if neighbor_position <= cell_count - 1:
							entry.right = cells[neighbor_position]
						neighbor_position = entry_index + rect_width
						if neighbor_position <= cell_count - 1:
							entry.down = cells[neighbor_position]
					elif grid_pointer.x == rect_width - 1:
						#right edge of grid
						entry.up = cells[entry_index - rect_width]
						entry.left = cells[entry_index - 1]
						neighbor_position = entry_index + rect_width
						if neighbor_position <= cell_count - 1:
							entry.down = cells[neighbor_position]
					else:
						#center of grid
						entry.up = cells[entry_index - rect_width]
						entry.left = cells[entry_index - 1]
						neighbor_position = entry_index + 1
						if neighbor_position <= cell_count - 1:
							entry.right = cells[neighbor_position]
						neighbor_position = entry_index + rect_width
						if neighbor_position <= cell_count - 1:
							entry.down = cells[neighbor_position]
					
				entry_index+= 1

func set_unit_target_position():
	for entry in cells:
		var cell_position = Vector3(entry.formation_position.x, 0, entry.formation_position.y)
		pass
	pass

class cell:
	var unit
	var formation_position: Vector2
	
	var up: cell = null
	var down: cell = null
	var left: cell = null
	var right: cell = null

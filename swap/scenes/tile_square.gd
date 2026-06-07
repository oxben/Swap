extends Node3D

var grid_x: int
var grid_y: int

# Whether the x axis is flipped
var flipped_x = false
# Whether the y axis is flipped
var flipped_z = false
# Wheter mouse hover was notified (used to notify hover only once)
var hover_notified = false

# Signal emitted when the tile is hovered
signal tile_hovered 
# Signal emitted when the tile is clicked
signal tile_clicked
# Signal emitted when the tile flip animation ends
signal tile_flipped
# Signal emitted when the tile fall animation ends
signal tile_fall_ended


enum Side { TOP = 0, RIGHT = 1, BOTTOM = 2, LEFT = 3}


func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseMotion:
		if not hover_notified:
			print("Mouse over shape ", shape_idx)
			hover_notified = true
			tile_hovered.emit(self.grid_x, self.grid_y, self.fix_side(shape_idx))
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Clicked shape ", shape_idx)
			tile_clicked.emit(self.grid_x, self.grid_y, self.fix_side(shape_idx))


func set_grid_pos(x: int, y: int):
	grid_x = x
	grid_y = y


func set_material(mat: StandardMaterial3D):
	 # @FIXME I'd like to simplify this subtree to get the mesh directly
	$Pivot/MeshInstance3D/tile_square_big/TileSquareBig.set_surface_override_material(0, mat)


func fix_side(side: int) -> int:
	match side:
		Side.TOP:
			if flipped_z:
				side = Side.BOTTOM
		Side.BOTTOM:
			if flipped_z:
				side = Side.TOP
		Side.LEFT:
			if flipped_x:
				side = Side.RIGHT
		Side.RIGHT:
			if flipped_x:
				side = Side.LEFT
	return side


func get_hinge(side: int) -> Dictionary:
	var half = Globals.SQUARE_TILE_SIZE * 0.5
	match side:
		Side.TOP:
			return {
				"point": global_position + Vector3(0, 0, -half),
				"axis": Vector3.RIGHT
			}
		Side.BOTTOM:
			return {
				"point": global_position + Vector3(0, 0, half),
				"axis": Vector3.RIGHT
			}
		Side.LEFT:
			return {
				"point": global_position + Vector3(-half, 0, 0),
				"axis": Vector3.FORWARD
			}
		Side.RIGHT:
			return {
				"point": global_position + Vector3(half, 0, 0),
				"axis": Vector3.FORWARD
			}
	return {}


func flip(side: int):
	if side in [Side.TOP, Side.BOTTOM]:
		flipped_z = not flipped_z
	elif side in [Side.LEFT, Side.RIGHT]:
		flipped_x = not flipped_x
	print("flip on %d" % [side])
	var data = get_hinge(side)
	var axis: Vector3 = data["axis"]
	var point: Vector3 = data["point"]

	var start_transform := global_transform

	# rotation around axis by 180°
	var q := Quaternion(axis.normalized(), PI)
	var end_basis := Basis(q) * start_transform.basis

	# BUT we must also rotate position around hinge point
	var start_pos := start_transform.origin
	var rel := start_pos - point
	var end_pos := point + (q * rel)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(_on_tween_finished)

	tween.tween_method(
		func(t):
			var b := start_transform.basis.slerp(end_basis, t)
			var p := start_pos.lerp(end_pos, t)
			global_transform = Transform3D(b, p),
		0.0,
		1.0,
		0.2
	)


func _on_tween_finished():
	"""
	Signal handler for tween animation
	"""
	tile_flipped.emit(self.grid_x, self.grid_y)


func fall(tile_offset: int):
	var offset = tile_offset * Globals.SQUARE_TILE_SIZE
	print("Move %s by %f" % [self.get_name(), offset])
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_on_fall_tween_finished)
	tween.tween_property(self, "position:z", position.z + offset, 0.3)


func _on_fall_tween_finished():
	"""
	Signal handler for fall tween animation
	"""
	tile_fall_ended.emit(self.grid_x, self.grid_y)


func _on_area_3d_mouse_exited() -> void:
	"""
	Reset hover notification
	"""
	if hover_notified:
		tile_hovered.emit(self.grid_x, self.grid_y, Globals.Sides.NONE)
	hover_notified = false

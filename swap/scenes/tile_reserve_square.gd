extends Node3D

const RESERVE_WIDTH  = 3
const RESERVE_HEIGHT = 4

# Tiles in reserve
var tiles: Array = []

# Dragging in progress
var dragging = false

# Tile currently being picked
var picked_tile = null

# Signal sent when a tile is picked in the reserve
signal reserve_tile_picked
# Signal sent when the tile picked is canceled 
signal reserve_tile_unpicked


func _ready() -> void:
	$Highlight.hide()


func reset():
	print("Reset reserve")
	# Free previous tiles if needed
	for y in tiles.size():
		for x in tiles[y].size():
			if tiles[y][x] != -1:
				tiles[y][x] = -1
				var tile = self.get_tile_node(x, y)
				if tile:
					# Tile must be renamed because queue_free() is asyncronous
					# and the tile name will be re-used by init_tile_grid()
					tile.name += "_freed"
					tile.queue_free()
	self.fill()
	

func fill():
	"""Fill tile reserve. """
	tiles.resize(RESERVE_HEIGHT)
	for y in range(RESERVE_HEIGHT):
		tiles[y] = []
		tiles[y].resize(RESERVE_WIDTH)
		for x in range(RESERVE_WIDTH):
			var color = randi_range(0, Globals.options.color_count-1)
			tiles[y][x] = -1
			add_tile(x, y, color)


func add_tile(x: int, y: int, color: int) -> bool:
	"""
	Add a tile node to the reserve at the given position with given the color.
	Returns true if the tile has been added, false otherwise.
	"""
	# Check the position is not used
	if tiles[y][x] != -1:
		print("There is already a tile on grid at [%d, %d]" % [x, y])
		return false
	tiles[y][x] = color
	var tile_scene = preload("res://scenes/tile_square.tscn")
	var tile = tile_scene.instantiate()
	tile.name = "Tile_%d_%d" % [ x, y]
	tile.position.x = x * Globals.SQUARE_TILE_SIZE + Globals.SQUARE_TILE_SIZE*0.5
	tile.position.z = y * Globals.SQUARE_TILE_SIZE + Globals.SQUARE_TILE_SIZE*0.5
	tile.set_material(Globals.color_materials[color])
	add_child(tile)
	return true


func get_tile_node(x: int, y: int):
	"""
	Get the tile node at given position
	"""
	var node_name = "Tile_%d_%d" % [x, y]
	if not has_node(node_name):
		return null
	return self.get_node(node_name)


func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Reserve Clicked shape ", shape_idx)
			self.pick_tile(shape_idx % RESERVE_WIDTH, shape_idx / RESERVE_WIDTH)


func _unhandled_input(event: InputEvent):
	"""
	Handles input actions
	"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Cancel tile pick
			if picked_tile != null:
				self.unpick_tile()


func pick_tile(x, y):
	print("Pick tile [%d, %d]" % [x, y])
	var tile = self.get_tile_node(x, y)
	if tile:
		picked_tile = tile
		$Highlight.position = tile.position
		$Highlight.show()
		reserve_tile_picked.emit(tiles[y][x])


func unpick_tile():
	picked_tile = null
	$Highlight.hide()
	reserve_tile_unpicked.emit()

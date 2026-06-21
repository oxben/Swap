extends Node3D

const GRID_SIZE = 12

# The tile grid organized as [row][column]
# Rows are stored from top to bottom, ie. top row is 0
# Columns are stored from left to right
var  tile_grid: Array[Array] = []

# List of tiles currently highlighted
var highlighted_tiles = []

# Are we waiting for a flip animations to end ?
var wait_flip_end = 0
# Are we waiting for a avalanche animations to end ?
var wait_avalanche_end = 0

var current_selected_reserve_color = -1

# Signal sent when a tile is clicked (used by stats)
signal tile_clicked
# Signal sent when tiles are destroyed
signal tile_destroyed
# Signal sent when avalanche has completed
signal avalanche_completed


func _ready():
	$TileReserve.reserve_tile_picked.connect(_on_reserve_tile_picked)
	$TileReserve.reserve_tile_unpicked.connect(_on_reserve_tile_unpicked)


func empty_board():
	"""
	Remove all tiles from the board.
	"""
	for y in tile_grid.size():
		for x in tile_grid[y].size():
			if tile_grid[y][x] != -1:
				tile_grid[y][x] = -1
				var tile = self.get_tile_node(x, y)
				if tile:
					# Tile must be renamed because queue_free() is asyncronous
					# and the tile name will be re-used by init_tile_grid()
					tile.name += "_freed"
					tile.queue_free()


func reset_board():
	# Free previous tiles if needed
	empty_board()
	$Highlight.hide()
	wait_flip_end = 0
	wait_avalanche_end = 0
	init_tile_grid()
	$TileReserve.reset()


func init_tile_grid():
	"""
	Initialize the tile grid
	"""
	tile_grid.resize(GRID_SIZE)
	for y in range(GRID_SIZE):
		tile_grid[y] = []
		tile_grid[y].resize(GRID_SIZE)
		for x in range(GRID_SIZE):
			var colors = []
			for i in range(Globals.options.color_count):
				colors.append(i)
			# Remove left neighbor color
			if x > 0:
				colors.erase(tile_grid[y][x-1])
			# Remove top neighbor color
			if y > 0:
				colors.erase(tile_grid[y-1][x])
			var color = colors.pick_random()
			# Instantiate one tile per position and set its material
			tile_grid[y][x] = -1
			self.add_tile(x, y, color)


func add_tile(x: int, y: int, color: int) -> bool:
	"""
	Add a tile node to the board at the given position with given the color.
	Returns true if the tile has been added, false otherwise.
	"""
	# Check the position is not used
	if tile_grid[y][x] != -1:
		print("There is already a tile on grid at [%d, %d]" % [x, y])
		return false
	tile_grid[y][x] = color
	var tile_scene = preload("res://scenes/tile_square.tscn")
	var tile = tile_scene.instantiate()
	tile.name = "Tile_%d_%d" % [ x, y]
	tile.position.x = x * Globals.SQUARE_TILE_SIZE + Globals.SQUARE_TILE_SIZE*0.5
	tile.position.z = y * Globals.SQUARE_TILE_SIZE + Globals.SQUARE_TILE_SIZE*0.5
	tile.set_material(Globals.color_materials[color])
	tile.set_grid_pos(x, y)
	tile.tile_hovered.connect(_on_tile_hovered)
	tile.tile_clicked.connect(_on_tile_clicked)
	tile.tile_flipped.connect(_on_tile_flipped)
	tile.tile_fall_ended.connect(_on_tile_fall_ended)
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


func get_neighbor_tile(x: int, y: int, side: int):
	"""
	Get neighbor's coordinates and side
	"""
	var neigh_x = -1
	var neigh_y = -1
	var neigh_side = -1
	match side:
		Globals.Sides.TOP:
			neigh_y = y - 1
			neigh_x = x
			neigh_side = Globals.Sides.BOTTOM
		Globals.Sides.BOTTOM:
			neigh_y = y + 1
			neigh_x = x
			neigh_side = Globals.Sides.TOP
		Globals.Sides.LEFT:
			neigh_x = x - 1
			neigh_y = y
			neigh_side = Globals.Sides.RIGHT
		Globals.Sides.RIGHT:
			neigh_x = x + 1
			neigh_y = y
			neigh_side = Globals.Sides.LEFT
	if neigh_x < 0 or neigh_x > GRID_SIZE \
		or neigh_y < 0 or neigh_y > GRID_SIZE:
			return null
	return { "x": neigh_x, "y": neigh_y, "side": neigh_side }


func save_state() -> Array[Array]:
	"""
	Make a copy of the tile grid and return it
	"""
	var saved_tile_grid: Array[Array] = []
	saved_tile_grid.resize(tile_grid.size())
	for i in tile_grid.size():
		saved_tile_grid[i] = tile_grid[i].duplicate()
	return saved_tile_grid


func restore_state(saved_tile_grid: Array[Array]):
	"""
	Restore tile grid
	"""
	empty_board()
	tile_grid = saved_tile_grid
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var color_idx = tile_grid[y][x]
			tile_grid[y][x] = -1
			if color_idx != -1:
				self.add_tile(x, y, color_idx)


func celebrate_success():
	if not is_empty():
		return
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if randf() < 0.25:
				var color = randi_range(0, Globals.options.color_count-1)
				add_tile(x, y, color)
				var tile = get_tile_node(x, y)
				destroy_tile(tile, color, 1.5)
				tile_grid[y][x] = -1


func _on_tile_hovered(x: int, y: int, side: int):
	"""
	Handle for hovered signal. Display highlight around tiles
	"""
	if wait_flip_end or wait_avalanche_end:
		# Ignore hovered signal while animations are in progress
		return
	if side == Globals.Sides.NONE:
		$Highlight.hide()
		return

	var neigh = self.get_neighbor_tile(x, y, side)
	if not neigh:
		return
	print("Highlight [%d, %d] and [%d, %d]" % [x, y, neigh.x, neigh.y])
	var tile = self.get_tile_node(x, y)
	var neigh_tile = self.get_tile_node(neigh.x, neigh.y)
	if tile and neigh_tile:
		var tile_rot_y = 0.0
		match side:
			Globals.Sides.TOP:
				tile_rot_y = 90.0
			Globals.Sides.BOTTOM:
				tile_rot_y = -90.0
			Globals.Sides.LEFT:
				tile_rot_y = -180.0
			Globals.Sides.RIGHT:
				tile_rot_y = 0.0
		$Highlight.position = tile.position
		$Highlight.rotation_degrees.y = tile_rot_y
		$Highlight.show()


func _on_tile_clicked(x: int, y: int, side: int):
	"""
	Handler for flip signal. Flip target tile and its neighbor if any
	"""
	if wait_flip_end > 0:
		print("Still flipping tiles. Skip")
		return
	tile_clicked.emit()
	var tile_name = "Tile_%d_%d" % [ x, y]
	print("%s flipped on side %d" % [tile_name, side])
	var tile := self.get_node(tile_name)
	if not tile:
		printerr("Failed to find tile %s" % [tile_name])
		return
	var neigh_x = -1
	var neigh_y = -1
	var neigh_side = -1
	match side:
		Globals.Sides.TOP:
			neigh_y = y - 1
			neigh_x = x
			neigh_side = Globals.Sides.BOTTOM
		Globals.Sides.BOTTOM:
			neigh_y = y + 1
			neigh_x = x
			neigh_side = Globals.Sides.TOP
		Globals.Sides.LEFT:
			neigh_x = x - 1
			neigh_y = y
			neigh_side = Globals.Sides.RIGHT
		Globals.Sides.RIGHT:
			neigh_x = x + 1
			neigh_y = y
			neigh_side = Globals.Sides.LEFT
	print("neigh [%d, %d]" % [neigh_x, neigh_y])
	if neigh_x >= 0 and neigh_x < GRID_SIZE and neigh_y >= 0 and neigh_y < GRID_SIZE:
		# Swap tile name
		var neigh_tile_name = "Tile_%d_%d" % [ neigh_x, neigh_y]
		var neigh_tile = self.get_node(neigh_tile_name)
		if not neigh_tile:
			# No tile found. Probably a hole on this side.
			# @FIXME this should be done somewhere else
			if current_selected_reserve_color != -1:
				$TileReserve.consume_tile()
				self.add_tile(neigh_x, neigh_y, current_selected_reserve_color)
				self.clear_grid()
			return
		# Flip tiles
		$AudioPlayerFlipTile.play()
		wait_flip_end = 2
		tile.flip(side)
		neigh_tile.flip(neigh_side)
		# Swap tiles color, name and grid position
		var color = tile_grid[y][x]
		tile_grid[y][x] = tile_grid[neigh_y][neigh_x]
		tile_grid[neigh_y][neigh_x] = color
		tile.name = "Tile_Tmp_Name"
		neigh_tile.name = tile_name
		tile.name = neigh_tile_name
		tile.set_grid_pos(neigh_x, neigh_y)
		neigh_tile.set_grid_pos(x, y)


func _on_tile_flipped(_x: int, _y: int):
	"""
	Signal handler for tile flip animations.
	Clear grid when no more animation are in progress.
	"""
	if wait_flip_end > 0:
		wait_flip_end -= 1
	if wait_flip_end == 0:
		$Highlight.hide()
		clear_grid()


func clear_grid():
	"""
	Check if tiles with similar color are neighbors and destroyed them if this is the case
	Return the number of tiles destroyed.
	"""
	print("Clear grid !")
	var destroyed_tiles = []
	var neigh_x = -1
	var neigh_y = -1

	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if tile_grid[y][x] != -1:
				# Check neighbor on the right
				neigh_x = x + 1
				neigh_y = y
				if neigh_x < GRID_SIZE and neigh_y < GRID_SIZE \
					and tile_grid[y][x] == tile_grid[neigh_y][neigh_x]:
					destroyed_tiles.append({"x": x, "y": y})
					destroyed_tiles.append({"x": neigh_x, "y": neigh_y})
				# Check neighbor below
				neigh_x = x
				neigh_y = y + 1
				if neigh_x < GRID_SIZE and neigh_y < GRID_SIZE \
					and tile_grid[y][x] == tile_grid[neigh_y][neigh_x]:
					destroyed_tiles.append({"x": x, "y": y})
					destroyed_tiles.append({"x": neigh_x, "y": neigh_y})
	var count = 0
	if destroyed_tiles.size() > 0:
		$AudioPlayerExplosion.play()
	for t in destroyed_tiles:
		# Destroy tile node and update tile grid
		var tile_name = "Tile_%d_%d" % [t.x, t.y]
		var tile = self.get_node(tile_name)
		var tile_color = tile_grid[t.y][t.x]
		if tile and tile_color != -1:
			tile_grid[t.y][t.x] = -1
			destroy_tile(tile, tile_color)
			count += 1
	tile_destroyed.emit(count)
	return count


func destroy_tile(tile, tile_color, explosion_lifetime=0.0):
	"""
	Remove tile from scene and and add explosion
	"""
	tile.queue_free()
	var explosion_scene = preload("res://scenes/tile_explosion.tscn")
	var explosion = explosion_scene.instantiate()
	explosion.position = tile.position + Vector3(0, 0.02, 0)
	explosion.color_mat = Globals.color_materials[tile_color]
	explosion.lifetime = explosion_lifetime
	add_child(explosion)


func avalanche():
	"""
	Computes tiles avalanche.
	"""
	print("Avalanche!")
	var moved_tiles = []
	for x in range(GRID_SIZE):
		# From bottom row to top row
		for y in range(GRID_SIZE-1, -1, -1):
			if tile_grid[y][x] != -1:
				# Check if there is empty space below the tile
				var test_y = y + 1
				var new_y = -1
				while test_y < GRID_SIZE and tile_grid[test_y][x] == -1:
					print("Empty space [%d, %d]" % [test_y, x])
					new_y = test_y
					test_y += 1
				if new_y >= 0:
					# Move tile to new empty space
					print("Move tile")
					tile_grid[new_y][x] = tile_grid[y][x]
					tile_grid[y][x] = -1
					var tile_name = "Tile_%d_%d" % [x, y]
					var new_tile_name = "Tile_%d_%d" % [x, new_y]
					var tile = self.get_node(tile_name)
					if tile:
						tile.name = new_tile_name
						tile.set_grid_pos(x, new_y)
						moved_tiles.append({"tile": tile, "offset": new_y-y})
	# Trigger movement of all moved tiles
	$Highlight.hide()
	wait_avalanche_end = moved_tiles.size()
	for move in moved_tiles:
		move.tile.fall(move.offset)
	return moved_tiles.size()


func is_empty():
	"""
	Tests if the grids is empty.
	"""
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if tile_grid[y][x] != -1:
				return false
	return true


func _on_tile_fall_ended(_x: int, _y: int):
	"""
	Handles signal sent when tile fall animations ends.
	When all expected animations have ended, clears grid and triggers another
	avalanche if some tiles have been destroyed by clear.
	"""
	if wait_avalanche_end > 0:
		wait_avalanche_end -= 1
	if wait_avalanche_end == 0:
		print("Avalanche complete")
		await get_tree().create_timer(0.25).timeout
		if clear_grid() > 0:
			await get_tree().create_timer(0.5).timeout
			avalanche()
		else:
			avalanche_completed.emit()


func _on_reserve_tile_picked(color_index: int):
	# @FIXME must find a better way to managed reserve
	current_selected_reserve_color = color_index
	pass


func _on_reserve_tile_unpicked():
	# @FIXME must find a better way to managed reserve
	current_selected_reserve_color = -1
	pass

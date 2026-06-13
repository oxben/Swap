extends Node3D

# Number of tiles to destroy in one flip to get a star
const STAR_FLIP : int = 5
# Maximum number of stars
const MAX_STARS : int = 10

# Statistics
var stats = {
	"score": 0,
	"tiles_clicked": 0,
	"tiles_destroyed": 0,
	"avalanche_triggered": 0,
	"stars_won" : 0,
}

# Saved states for the game. Used for undo mechanism.
var game_states: Array = []


func _ready() -> void:
	$PanelScore/VersionLabel.text = "v.%03d" % [Globals.version]
	$PlaygroundSquare.tile_clicked.connect(_on_tile_clicked)
	$PlaygroundSquare.tile_destroyed.connect(_on_tile_destroyed)
	$ConfigDialog.configuration_applied.connect(_on_new_game_configured)
	start_game()


func _unhandled_input(ev):
	"""
	Handles input actions
	"""
	if ev.is_action_released("Quit"):
		quit_game()
	elif ev.is_action_released("Avalanche"):
		trigger_avalanche()
	elif ev.is_action_released("RestartGame"):
		start_game()
	elif ev.is_action_released("Undo"):
		restore_state()
	elif ev.is_action_released("ChangeColors"):
		init_tile_colors(false)


func start_game():
	$PanelScore/ButtonAvalanche.disabled = not Globals.options.avalanche_enabled
	game_states.clear()
	$PanelScore/ButtonUndo.disabled = true
	reset_stats()
	init_tile_colors()
	$PlaygroundSquare.reset_board()


func configure_new_game():
	"""
	Display dialog to configure new game
	"""
	$ConfigDialog.popup_centered()


func init_tile_colors(new_materials: bool = true):
	"""
	Initialize the color for the tiles
	"""
	if Globals.color_materials.size() != Globals.options.color_count:
		Globals.color_materials.resize(Globals.options.color_count)
	# Instantiate new materials if needed
	if new_materials:
		for i in range(Globals.options.color_count):
			var base_material := preload("res://assets/textures/tile_material.tres")
			var material := base_material.duplicate() as StandardMaterial3D
			Globals.color_materials[i] = material
	# Set material properties
	for i in range(Globals.options.color_count):
		var color = Color(randf_range(0.3, 1.0), randf_range(0.3, 1.0), randf_range(0.3, 1.0))
		var material = Globals.color_materials[i]
		material.albedo_color = color
		material.metallic = 0.2 #0.5
		material.roughness = 0.5 #0.5
		Globals.color_materials[i] = material


func reset_stats():
	for key in stats:
		stats[key] = 0
	update_score()


func quit_game():
	get_tree().quit()


func trigger_avalanche():
	if Globals.options.avalanche_count == -1 \
		or stats.avalanche_triggered <= Globals.options.avalanche_count:
			var moved_tiles = $PlaygroundSquare.avalanche()
			if moved_tiles > 1:
				stats.avalanche_triggered += 1

	if Globals.options.avalanche_count != -1 \
		and stats.avalanche_triggered >= Globals.options.avalanche_count:
			$PanelScore/ButtonAvalanche.disabled = true


func ask_confirmation(message: String, function: Callable):
	"""
	Displays the confirmation dialog with the given message.
	If the answer is yes calls the given function.
	"""
	var dialog = $ConfirmationDialog
	dialog.dialog_text = message
	dialog.ok_button_text = "Yes"
	dialog.cancel_button_text = "No"
	for c in dialog.confirmed.get_connections():
		dialog.confirmed.disconnect(c.callable)
	dialog.confirmed.connect(function)
	dialog.popup_centered()


func show_message(message: String):
	"""
	Displays the confirmation dialog with the given message.
	If the answer is yes calls the given function.
	"""
	var dialog = $AcceptDialog
	dialog.dialog_text = message
	dialog.popup_centered()


func update_score():
	$PanelScore/EditScore.text = "%d" % [stats.score]
	$PanelScore/EditClicks.text = "%d" % [stats.tiles_clicked]
	$PanelScore/PanelStars.light_stars(stats.stars_won)


func save_state():
	var state = {}
	state["tile_grid"] = $PlaygroundSquare.save_state()
	state["tile_reserve"] = $PlaygroundSquare/TileReserve.save_state()
	state["stats"] = stats.duplicate()
	game_states.append(state)
	$PanelScore/ButtonUndo.disabled = false


func restore_state():
	var saved_state = game_states.pop_back()
	if saved_state:
		$PlaygroundSquare.restore_state(saved_state["tile_grid"])
		$PlaygroundSquare/TileReserve.restore_state(saved_state["tile_reserve"])
		stats = saved_state["stats"]
		update_score()
	if game_states.size() == 0:
		$PanelScore/ButtonUndo.disabled = true


func _on_tile_clicked():
	"""
	Handles signal sent when tiles are clicked
	"""
	save_state()
	stats.tiles_clicked += 1
	self.update_score()


func _on_tile_destroyed(count: int):
	"""
	Handles signal sent when tiles are destroyed
	"""
	# Update score: exponential growth
	stats.score += count * count
	stats.tiles_destroyed += count
	# smooth scaling without exploding too fast.
	# stats.score = int(count * (count + 1) / 2) - 1
	if count >= STAR_FLIP:
		$Title.flip()
		stats.stars_won = min(stats.stars_won + 1, MAX_STARS)
	self.update_score()
	if $PlaygroundSquare.is_empty():
		self.show_message("Success!")


func _on_button_avalanche_pressed() -> void:
	"""
	Handles click on Avalanche button
	"""
	self.trigger_avalanche()


func _on_button_restart_pressed() -> void:
	"""
	Handles click on Restart button
	"""
	if stats.tiles_clicked > 0:
		ask_confirmation("Are you sure you want to start a new game?", configure_new_game)
	else:
		self.configure_new_game()


func _on_button_quit_pressed() -> void:
	"""
	Handles click on Quit button
	"""
	ask_confirmation("Are you sure you want to quit the game?", quit_game)


func _on_button_configure_pressed() -> void:
	"""
	Handles click on Configure button
	"""
	self.configure_new_game()


func _on_new_game_configured() -> void:
	"""
	Handles the signal emitted by game config dialog when OK/Play is pressed
	"""
	self.start_game()


func _on_button_undo_pressed() -> void:
	"""
	Handles click on Undo button
	"""
	restore_state()


func _on_button_change_colors_pressed() -> void:
	"""
	Handles click on Change Colors button
	"""
	init_tile_colors(false)

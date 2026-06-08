extends Node3D

# Number of tiles to destroy in one flip to get a star
const STAR_FLIP : int = 6

# Statistics
var stats = {
	"score": 0,
	"tiles_clicked": 0,
	"tiles_destroyed": 0,
	"avalanche_triggered": 0,
	"stars_won" : 0,
}

func _ready() -> void:
	$PlaygroundSquare.tile_clicked.connect(_on_tile_clicked)
	$PlaygroundSquare.tile_destroyed.connect(_on_tile_destroyed)
	start_game()


func _unhandled_input(ev):
	"""
	Handles input actions
	"""
	if ev.is_action_released("Quit"):
		quit_game()
	elif ev.is_action_released("Avalanche"):
		stats.avalanche_triggered += 1
		$PlaygroundSquare.avalanche()
	elif ev.is_action_released("RestartGame"):
		start_game()


func start_game():
	reset_stats()
	init_tile_colors()
	$PlaygroundSquare.reset_board()


func init_tile_colors():
	"""
	Initialize the color for the tiles
	"""
	Globals.color_materials.resize(Globals.options.color_count)
	var base_material := preload("res://assets/textures/tile_material.tres")
	for i in range(Globals.options.color_count):
		var color = Color(randf_range(0.3, 1.0), randf_range(0.3, 1.0), randf_range(0.3, 1.0))
		var material := base_material.duplicate() as StandardMaterial3D
		material.albedo_color = color
		material.metallic = 0.2 #0.5
		material.roughness = 0.5 #0.5
		Globals.color_materials[i] = material


func reset_stats():
	for key in stats:
		stats[key] = 0


func quit_game():
	get_tree().quit()


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


func _on_tile_clicked():
	"""
	Handles signal sent when tiles are clicked
	"""
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
		stats.stars_won = min(stats.stars_won + 1, STAR_FLIP)
	self.update_score()
	if $PlaygroundSquare.is_empty():
		self.show_message("Success!")


func _on_button_avalanche_pressed() -> void:
	"""
	Handles click on Avalanche button
	"""
	stats.avalanche_triggered += 1
	$PlaygroundSquare.avalanche()


func _on_button_restart_pressed() -> void:
	"""
	Handles click on Restart button
	"""
	if stats.tiles_clicked > 0:
		ask_confirmation("Are you sure you want to restart this level?", start_game)
	else:
		start_game()


func _on_button_quit_pressed() -> void:
	"""
	Handles click on Quit button
	"""
	ask_confirmation("Are you sure you want to quit the game?", quit_game)

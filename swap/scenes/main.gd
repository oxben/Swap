extends Node3D

# Statistics
var stats = {
	"score": 0,
	"tile_clicked": 0,
	"avalanche_triggered": 0
}

func _ready() -> void:
	$PlaygroundSquare.tile_clicked.connect(_on_tile_clicked)


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
	$PlaygroundSquare.reset_board()


func quit_game():
	get_tree().quit()


func reset_stats():
	for key in stats:
		stats[key] = 0


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


func _on_tile_clicked():
	"""
	Handles signal sent when tiles are clicked
	"""
	stats.tile_clicked += 1


func _on_tile_destroyed(count: int):
	"""
	Handles signal sent when tiles are destroyed
	"""
	# Update score: exponential growth
	stats.score += count * count
	# smooth scaling without exploding too fast.
	# stats.score = int(count * (count + 1) / 2) - 1
	# print("%d tiles -> %d pts" % [count, stats.score])


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
	if stats.tile_clicked > 0:
		var dialog = $ConfirmationDialog
		ask_confirmation("Are you sure you want to restart this level?", start_game)
	else:
		start_game()


func _on_button_quit_pressed() -> void:
	"""
	Handles click on Quit button
	"""
	ask_confirmation("Are you sure you want to restart this level?", quit_game)

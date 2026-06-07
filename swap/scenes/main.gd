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
		get_tree().quit()
	elif ev.is_action_released("Avalanche"):
		stats.avalanche_triggered += 1
		$PlaygroundSquare.avalanche()


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

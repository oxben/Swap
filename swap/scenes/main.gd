extends Node3D

# Statistics
var stats = {
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
	stats.tile_clicked += 1

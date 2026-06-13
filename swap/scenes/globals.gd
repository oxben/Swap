extends Node

#
# Global definitions
#

# Release version
const version = 3

# Square tile sides
enum Sides { TOP = 0, RIGHT = 1, BOTTOM = 2, LEFT = 3, NONE=99}

# Square tile size
const SQUARE_TILE_SIZE = 0.1

# Default game option values
const default_options = {
	color_count          = 3,
	avalanche_enabled    = true,
	avalanche_count      = -1,
	tile_reserve_enabled = true,
}

# Game options
var options = {
	color_count          = default_options.color_count,
	avalanche_enabled    = default_options.avalanche_enabled,
	avalanche_count      = default_options.avalanche_count,
	tile_reserve_enabled = default_options.tile_reserve_enabled,
}

# Material associated with each tile color.
var color_materials: Array = []

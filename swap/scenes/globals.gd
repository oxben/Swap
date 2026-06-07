extends Node

#
# Global definitions
#

# Square tile sides
enum Sides { TOP = 0, RIGHT = 1, BOTTOM = 2, LEFT = 3, NONE=99}

# Tile color IDs
enum Colors { COLOR_1, COLOR_2, COLOR_3, COLOR_4 }

# Square tile size
const SQUARE_TILE_SIZE = 0.1

 # Game options
var options = {
	color_count = 4
}

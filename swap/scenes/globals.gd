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

#
# High scores
#
const HIGH_SCORES_FILE: String = "user://highscores.json"
const HIGH_SCORES_MAX: int     = 10;

var high_score_entry = {
	"name":	"",
	"score": 0,
	"colors" : 0,
}
var high_scores = {
	"version" : 1,
	"scores": [],
}

#-------------------------------------------------------------------------------

func load_high_scores() -> void:
	"""
	Load high scores from JSON file
	"""
	# Create empty high scores
	for i in HIGH_SCORES_MAX:
		self.high_scores["scores"].append({ "name": "", "score": 0, "colors": 0})

	if not FileAccess.file_exists(HIGH_SCORES_FILE):
		return
	var file = FileAccess.open(HIGH_SCORES_FILE, FileAccess.READ)
	var json_text = file.get_as_text()
	var loaded_high_scores = JSON.parse_string(json_text)
	if not loaded_high_scores:
		return
	if "version" in loaded_high_scores and \
		loaded_high_scores["version"] == self.high_scores["version"]:
		self.high_scores = loaded_high_scores


func save_high_scores() -> void:
	"""
	Save high scores to JSON file
	"""
	var file = FileAccess.open(HIGH_SCORES_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify(self.high_scores))


func is_high_score(score: int) -> bool:
	"""
	Tell whether the given score is higher than one of the stored high scores
	"""
	var scores : Array = high_scores["scores"]
	for i in HIGH_SCORES_MAX:
		if score > scores[i]["score"]:
			return true
	return false


func update_high_scores(player_name: String, score: int, colors: int) -> bool:
	"""
	Update the high scores.
	Return true if the score passed in is a new high score, false otherwise.
	"""
	if not is_high_score(score):
		return false
	# Add new high score to array, sort and remove last one
	var scores : Array = high_scores["scores"]
	scores.append({"name": player_name, "score": score, "colors": colors})
	scores.sort_custom(sort_by_score_desc)
	scores.resize(HIGH_SCORES_MAX)
	return true


func sort_by_score_desc(a: Dictionary, b: Dictionary) -> bool:
	return a["score"] > b["score"]

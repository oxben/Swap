extends Window

# Whether all the controls have been added to the score grid
var score_grid_initialized : bool = false

func _on_about_to_popup() -> void:
	"""
	Initialize control with current options values
	"""
	self.exclusive = true
	if not score_grid_initialized:
		init_score_grid()
	show_scores()
	$Panel/VBoxContainer/CloseButton.grab_focus()


func add_score_label(label_name: String, label_text: String) -> void:
		var label_settings = preload("res://assets/ui/high_score_entry_label_settings.tres")
		var label = Label.new()
		label.name = label_name
		label.text = label_text
		label.label_settings = label_settings
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		$Panel/VBoxContainer/ScoresGrid.add_child(label)


func init_score_grid() -> void:
	"""
	Add all the labels required to display the high scores
	"""
	for i in Globals.HIGH_SCORES_MAX:
		add_score_label("RankLabel%02d" % [i], "-")
		add_score_label("ScoreLabel%02d" % [i], "-")
		add_score_label("NameLabel%02d" % [i], "-")
		add_score_label("ColorsLabel%02d" % [i], "-")
	score_grid_initialized = true


func show_scores() -> void:
	var grid = $Panel/VBoxContainer/ScoresGrid
	for i in Globals.HIGH_SCORES_MAX:
		var label = null
		label = grid.get_node("RankLabel%02d" % [i])
		label.text = str(i+1)
		label = grid.get_node("ScoreLabel%02d" % [i])
		label.text = "%08d" % [Globals.high_scores.scores[i]["score"]]
		label = grid.get_node("NameLabel%02d" % [i])
		label.text = Globals.high_scores.scores[i]["name"]
		label = grid.get_node("ColorsLabel%02d" % [i])
		label.text = "▢".repeat(Globals.high_scores.scores[i]["colors"])



func _unhandled_input(ev):
	"""
	Handles input actions
	"""
	if ev.is_action_released("Quit"):
		self.hide()


func _on_close_button_pressed() -> void:
	self.hide()

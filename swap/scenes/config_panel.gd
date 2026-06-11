extends Window

# Signal sent when config pnale is validated
signal configuration_applied


func _on_about_to_popup() -> void:
	"""
	Initialize control with current options values
	"""
	self.exclusive = true
	$Panel/ColorCountSlider.value = Globals.options.color_count
	$Panel/AvalancheCheckButton.button_pressed = Globals.options.avalanche_enabled
	$Panel/AvalancheLimitSpinBox.value = Globals.options.avalanche_count
	$Panel/TileReserveCheckButton.button_pressed = Globals.options.tile_reserve_enabled
	$Panel/ButtonOK.grab_focus()


func _on_button_reset_pressed() -> void:	
	"""
	Reset controls to default option values
	"""
	$Panel/ColorCountSlider.value = Globals.default_options.color_count
	$Panel/AvalancheCheckButton.button_pressed = Globals.default_options.avalanche_enabled
	$Panel/AvalancheLimitSpinBox.value = Globals.default_options.avalanche_count
	$Panel/TileReserveCheckButton.button_pressed = Globals.default_options.tile_reserve_enabled


func _on_button_ok_pressed() -> void:
	"""
	Set options
	"""
	Globals.options.color_count = $Panel/ColorCountSlider.value
	Globals.options.avalanche_enabled = $Panel/AvalancheCheckButton.button_pressed
	Globals.options.avalanche_count = $Panel/AvalancheLimitSpinBox.value
	Globals.options.tile_reserve_enabled = $Panel/TileReserveCheckButton.button_pressed
	self.hide()
	configuration_applied.emit()


func _on_button_cancel_pressed() -> void:
	self.hide()


func _on_color_count_slider_value_changed(value: float) -> void:
	$Panel/ColorCountEdit.text = str(int(value))


func _unhandled_input(ev):
	"""
	Handles input actions
	"""
	if ev.is_action_released("Quit"):
		self.hide()

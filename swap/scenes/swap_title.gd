extends Node3D

var is_flipping = false

func flip():
	if is_flipping:
		return
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_on_rotation_tween_finished)
	tween.tween_property(self, "rotation_degrees:z", -360, 1.5)
	is_flipping = true


func _on_rotation_tween_finished():
	is_flipping = false
	rotation_degrees.z = 0.0

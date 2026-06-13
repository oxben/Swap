extends Panel

const star_count: int = 10

func light_stars(count: int):
	# delay a bit the display
	await get_tree().create_timer(0.5).timeout
	for i in range(star_count):
		var star = self.get_node("SpriteStar_%d" % [i])
		var prev_frame = star.frame
		star.frame = 1 if i < count else 0
		if star.frame > prev_frame:
			$AudioPlayerNewStar.play()

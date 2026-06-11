extends Panel

const star_count: int = 10

func light_stars(count: int):
	for i in range(star_count):
		var star = self.get_node("SpriteStar_%d" % [i])
		star.frame = 1 if i < count else 0

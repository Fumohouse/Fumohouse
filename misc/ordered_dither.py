# Generates a threshold map for ordered dithering.
# Based on the recursive definition in https://en.wikipedia.org/wiki/Ordered_dithering

import numpy as np
from PIL import Image


def pattern(n):
	if n == 2:
		return 1 / 4 * np.matrix([[0, 2], [3, 1]])

	prev_scaled = n * n * pattern(n / 2)

	return (1 / (n * n)) * np.vstack((
		np.hstack((prev_scaled, prev_scaled + 2)),
		np.hstack((prev_scaled + 3, prev_scaled + 1))
	))


n = 128
p = pattern(n)
img = Image.fromarray((255 * p).astype("byte"), "L")
img.save("ordered_dither.png")

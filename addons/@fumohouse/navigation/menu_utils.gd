extends RefCounted

const MARGIN := 5.0
const TRANSITION_DURATION = 0.35


static func common_tween(this: Node, vis: bool) -> Tween:
	return this.create_tween().set_ease(Tween.EASE_OUT).set_trans(
		Tween.TRANS_CIRC if vis else Tween.TRANS_QUAD
	)

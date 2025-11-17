package pducc

import "core:math"
import "core:fmt"

Collider_Kind :: enum {
	RECT,
	CIRCLE,
}

Collider :: struct {
	kind:   Collider_Kind,
	origin: [2]f32,
	scale:  [2]f32,
	radius: f32,
}

rect_collision :: proc(a, b: Collider) -> bool {
	assert(a.kind == .RECT && b.kind == .RECT, "A and B must both be Rect Colliders")
	//TODO: How do we detect collision on a rotated box
	if ((a.origin.x + a.scale.x) >= b.origin.x && (a.origin.x) <= (b.origin.x + b.scale.x)) &&
		((a.origin.y + a.scale.y) >= b.origin.y && (a.origin.y) <= (b.origin.y + b.scale.y)) {
			return true
	}
	return false
}

circle_collision :: proc(a, b: Collider) -> bool {
	assert(a.kind == .CIRCLE && a.kind == .CIRCLE, "A and B must both be Circle Colliders")
	dist_x := a.origin.x - b.origin.x
	dist_y := a.origin.y - b.origin.y
	dist := math.sqrt((dist_x * dist_x) + (dist_y * dist_y))
	return dist <= (a.radius + b.radius)
}

circle_rect_collision :: proc(a, b: Collider) -> bool {

	return false
}

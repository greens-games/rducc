package peck

import "core:math"

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
	return ((a.origin.x + a.scale.x) > b.origin.x && (a.origin.x) < (b.origin.x + b.scale.x)) &&
		((a.origin.y + a.scale.y) > b.origin.y && (a.origin.y) < (b.origin.y + b.scale.y))
}

//TODO: This still doesn't work need to spend more time on physics
circle_collision :: proc(a, b: Collider) -> bool {
	assert(a.kind == .CIRCLE && b.kind == .CIRCLE, "A and B must both be Circle Colliders")
	dist_x := a.origin.x - b.origin.x
	dist_y := a.origin.y - b.origin.y
	dist := math.sqrt((dist_x * dist_x) + (dist_y * dist_y))
	return dist <= math.max(a.radius, b.radius)
}

//NOTE: Yoinked from https://www.jeffreythompson.org/collision-detection/circle-rect.php
circle_rect_collision :: proc(rect, circle: Collider) -> bool {
	assert(rect.kind == .RECT && circle.kind == .CIRCLE, "First arg must be RECT Collider and second arg must both be CIRCLE Collider")
	// temporary variables to set edges for testing
	testX := circle.origin.x
	testY := circle.origin.y

	// which edge is closest?
	if (circle.origin.x < rect.origin.x) {
		testX = rect.origin.x
	}      // test left edge
	else if (circle.origin.x > rect.origin.x+rect.scale.x) {
		testX = rect.origin.x+rect.scale.x
	}   // right edge
	if (circle.origin.y < rect.origin.y) {
		testY = rect.origin.y
	}      // top edge
	else if (circle.origin.y > rect.origin.y+rect.scale.y) {
		testY = rect.origin.y+rect.scale.y
	}   // bottom edge

	// get distance from closest edges
	distX := circle.origin.x-testX;
	distY := circle.origin.y-testY;
	distance := math.sqrt( (distX*distX) + (distY*distY) );

	// if the distance is less than the radius, collision!
	if (distance <= circle.radius) {
		return true;
	}
	return false
}

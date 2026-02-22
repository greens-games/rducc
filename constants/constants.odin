package constants

import "../peck"
import "../plumage"

CELL_SIZE :: 32

Entity_Kind :: enum {
	PLAYER,
	ENEMY,
	PROJECTILE,
	PLATFORM,
	GOAL,
	PARTICLE,
}

Levels :: enum {
	ONE,
	TWO,
	V,
}

Trait :: enum {
	STATIC,
	MOVEABLE,
}

Cell :: struct {
	col: f32,
	row: f32,
}

Entity :: struct {
	kind:          Entity_Kind,
	traits:        Trait,
	waypoints:     []Cell,
	curr_waypoint: i32,
	pos:           [2]f32,
	velocity:      [2]f32,
	scale:         [2]f32,
	colour:        plumage.Colour,
	collider:      peck.Collider,
	direction:     i8,
	texture_hndl:  i32,
	alive:         bool,
	health:        i32,
	damage:        i32,
	h_speed:       f32,
	v_speed:       f32,
}

//TODO: THESE SHOULD NOT BE HERE MOVE THEM IN THE NEXT CLEANUP
bullet_count := 0
curr_jump_time: f32 = 0.0
bullet_cap := 100 
jumps := 1
jumping := false
curr_level := Levels.ONE

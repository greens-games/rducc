package main

import "core:math/linalg"
import "rducc"
import "pducc"
import "core:fmt"
import "core:math"
import "core:mem"


Entity :: struct {
	pos:          [2]f32,
	scale:        [2]f32,
	velocity:     [2]f32,
	direction:    [2]f32,
	rotation:     f32,
	fire_rate_cd: f32,
	fire_rate:    f32,
	bullet_range: f32,
	to_free:      bool,
	collider:     pducc.Collider,
}

/* 
curr_rotation = math.to_degrees(math.atan2((game_mem.player.y ) - m_pos.y, (game_mem.player.x ) - m_pos.x))
*/

debug_draw_colliders := true

//TODO: Add hot reloading
main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	run()
}

//TODO: TEST FOR DRAWING 1 BOX FOR EACH 16x16 SECITON OF WINDOW
run :: proc() {
	entities: [1024]Entity
	entity_count := 0
	rducc.window_open(980,620,"RDUCC DEMO")
	rducc.renderer_init()
	rducc.shader_load("res/vert_2d.glsl", "res/frag_primitive.glsl")
	bullets := make_dynamic_array([dynamic]Entity)
	guy: Entity
	//TODO:Find a way to do "canonical" positioning (i.e position by meters and move m/s rather than pixels)
	guy.pos = {f32(rducc.ctx.window_width)/2.,f32(rducc.ctx.window_height)/2.}
	guy.scale = {16,32}
	guy.collider.origin = guy.pos
	guy.collider.scale = {16.,32.}
	guy.collider.kind = .RECT
	guy.fire_rate = 0.5
	entities[entity_count] = guy
	entity_count += 1
	curr_rotation: f32 = 0.
	player := &entities[0]

	enemy: Entity
	enemy.pos = {150.,150.}
	enemy.scale = {48,48}
	enemy.collider = {
		origin = enemy.pos,
		scale  = enemy.scale,
	}
	entities[entity_count] = enemy
	entity_count += 1

	for !rducc.window_close() {
		//NOTE: This porbably shouldn't stay find a better way to handle freeing bullets
		bullets_to_free := make_dynamic_array([dynamic]Entity, context.temp_allocator)

		m_pos := rducc.window_mouse_pos()
		curr_rotation_radians := math.atan2((player.pos.y ) - m_pos.y, (player.pos.x ) - m_pos.x)
		curr_rotation_degrees := math.to_degrees(curr_rotation_radians)
		dt := rducc.time_delta_get()
		player.fire_rate_cd -= f32(dt)
		player.rotation = curr_rotation_degrees
		if rducc.window_is_mouse_button_down(.MOUSE_BUTTON_LEFT) && player.fire_rate_cd <= 0 {
			bullet: Entity
			bullet.pos = player.pos
			bullet.rotation = player.rotation
			dist: [2]f32 = m_pos - player.pos
			bullet.direction = linalg.vector_normalize(dist)
			append(&bullets, bullet)
			player.fire_rate_cd = player.fire_rate
			fmt.println("CURR_ROTATION_RADIANS: ",curr_rotation_radians)
		}

		if rducc.window_is_key_down(.KEY_A) {
			player.velocity.x -= f32(100. * dt)
		}
		if rducc.window_is_key_down(.KEY_D) {
			player.velocity.x += f32(100. * dt)
		}

		if rducc.window_is_key_down(.KEY_S) {
			player.velocity.y -= f32(100. * dt)
		}

		if rducc.window_is_key_down(.KEY_W) {
			player.velocity.y += f32(100. * dt)
		}

		if pducc.rect_collision({
			origin = player.collider.origin + player.velocity, 
			scale = player.collider.scale
			}, 
			entities[1].collider) {
			player.velocity = {}
		}
		player.pos += player.velocity
		player.collider.origin += player.velocity
		player.velocity = {}
		rducc.renderer_background_clear(rducc.GRAY)
		for &bullet in bullets {
			bullet.velocity += bullet.direction * 250. * f32(dt)
			/* TODO: Check for collision:
				This may warrant doing a tile_map type shtick so I can just check the things in the area
				Check all entities in the world's position which is slow
				Check only things in an area without tile_map which but we need a way to know the things in the area */
			bullet.pos += bullet.velocity
			bullet.velocity = {}
			rducc.renderer_box({bullet.pos, {8,16}, bullet.rotation}, {rducc.BLACK})
			if bullet.pos.x > f32(rducc.window_width()) || bullet.pos.x < 0. {
				bullet.to_free = true
			} else if bullet.pos.y > f32(rducc.window_height()) || bullet.pos.y < 0. {
				bullet.to_free = true
			}
		}

		//NOTE: This is really bad and should probably not stay, find a better way to free bullets
		for bullet, i in bullets {
			if bullet.to_free {
				append(&bullets_to_free, bullet)
				ordered_remove(&bullets, i)
			}
		}
		for idx in 0..<entity_count {
			e := entities[idx]
			rducc.renderer_box({e.pos, e.scale, e.rotation}, {rducc.BLUE})
			if debug_draw_colliders {
				rducc.renderer_box_lines({e.collider.origin, e.collider.scale, e.rotation}, {rducc.GREEN})
			}
		}
		free_all()
	}
}


package main

import "core:image"
import "core:image/png"
import "core:image/bmp"
import "core:mem"
import "core:mem/virtual"
import "core:fmt"

import "debug"
import "rducc"
import "pducc"


/**
Table of Contents:
	RESET
	CLEANUP
	RENDER
	PHYSICS
	INIT
*/

Game_State :: enum {
	PLAYING,
	MENU,
	PAUSED,
}

Entity :: struct {
	pos:       [2]f32,
	scale:     [2]f32,
	collider:  pducc.Collider,
	direction: i8,
	texture_hndl: i32,
}

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


run :: proc() {
	rducc.init(980,620,"RDUCC DEMO")
	curr_rotation: f32 = 0.
	debug_mode := false
	game_state: Game_State
	
	game_perm_arena: virtual.Arena 
	arena_err := virtual.arena_init_static(&game_perm_arena)
	assert(arena_err == nil)
	game_perm_arena_allocator := virtual.arena_allocator(&game_perm_arena)

	loaded_textures := make_dynamic_array([dynamic]rducc.Ducc_Texture, game_perm_arena_allocator)

	percy_image, percy_image_ok := image.load_from_bytes(#load("res/scuffed_percy.png"))
	percy_texture := rducc.sprite_load(percy_image.pixels.buf[:], percy_image.height, percy_image.width)
	append(&loaded_textures, percy_texture)
	percy_entity := Entity {
		pos =   {150, 150},
		scale = {32, 32},
		texture_hndl = i32(len(loaded_textures) - 1),
		direction = 1,
	}

	enemy_image, enemy_image_ok := image.load_from_bytes(#load("res/player_filled.png"))
	enemy_texture := rducc.sprite_load(enemy_image.pixels.buf[:], enemy_image.height, enemy_image.width)
	append(&loaded_textures, enemy_texture)
	enemy_entity := Entity {
		pos       = [2]f32{185, 150},
		scale     = [2]f32{32, 32},
	}

	collider  := pducc.Collider {
		kind   = .CIRCLE,
		origin = enemy_entity.pos,
		scale  = enemy_entity.scale,
		radius = enemy_entity.scale.x,
	}
	enemy_entity.collider = collider

	game_frame_arena: virtual.Arena 
	arena_err = virtual.arena_init_static(&game_frame_arena)
	assert(arena_err == nil)
	game_frame_arena_allocator := virtual.arena_allocator(&game_frame_arena)

	bullet_cap := 100
	bullets := make_slice([]Entity, bullet_cap, game_frame_arena_allocator)
	bullet_count := 0

	m_pos_change := [2]f32{0.0, 0.0}
	prev_m_pos := rducc.window_mouse_pos()

	velocity: [2]f32
	direction: i8 = 1

	r_group2 := rducc.render_group_create()
	for !rducc.window_close() {
		//TODO: Get some actual menu and pausing stuff going
		if rducc.window_is_key_pressed(.KEY_P) {
			game_state = .PLAYING
		}
		if game_state == .PAUSED {
			continue
		}
		//TC: INIT
		m_pos := rducc.window_mouse_pos()
		m_pos_change = m_pos - prev_m_pos

		dt := f32(rducc.time_delta_get())

		//TC: INPUT
		if rducc.window_is_mouse_button_down(.MOUSE_BUTTON_LEFT) {
			m_collider: pducc.Collider
			m_collider.kind = .RECT
			m_collider.origin = m_pos
			m_collider.scale = [2]f32{10, 10}
			percy_collider: pducc.Collider
			percy_collider.kind = .RECT
			percy_collider.origin = percy_entity.pos
			percy_collider.scale = percy_entity.scale
			if pducc.rect_collision(m_collider, percy_collider) {
				//TODO: This can sometimes stop being detected when moving too fast
				percy_entity.pos += m_pos_change
			}
		}

		if rducc.window_is_key_pressed(.KEY_GRAVE_ACCENT) {
			debug_mode = !debug_mode
		}

		if rducc.window_is_key_pressed(.KEY_SPACE) {
			game_state = .PAUSED
		}


		if rducc.window_is_key_pressed(.KEY_Q) {
			{
				bullet: Entity
				start_pos := f32(10 * direction) * f32((direction > 0) ? 2.5 : 1.5)
				bullet.pos = [2]f32{percy_entity.pos.x  + start_pos, percy_entity.pos.y + percy_entity.scale.y/2}
				bullet.scale = [2]f32{16, 16}
				bullet.direction = direction
				collider: pducc.Collider
				collider.scale = bullet.scale
				collider.origin = bullet.pos
				collider.kind = .CIRCLE
				collider.radius = bullet.scale.x
				bullet.collider = collider
				if bullet_count >= bullet_cap {
					bullet_count = 0
				}
				bullets[bullet_count] = bullet
				bullet_count += 1
			}
		}

		if rducc.window_is_key_down(.KEY_D) {
			velocity.x += (250 * f32(dt))
			direction = 1
		}

		if rducc.window_is_key_down(.KEY_A) {
			velocity.x -= (250 * f32(dt))
			direction = -1
		}

		if rducc.window_is_key_pressed(.KEY_R) {
			rducc.shader_load("res/vert_2d.glsl", "res/frag_texture.glsl")
			rducc.projection_set()
		}

		// TC: PHYSICS
		percy_entity.pos += velocity
		for idx in 0..<bullet_count {
			b := &bullets[idx]
			b_velocity := (300 * dt * f32(b.direction))
			if pducc.circle_collision(b.collider, enemy_entity.collider) {
				b_velocity = 0.0
			}
			b.pos.x = clamp(b.pos.x + b_velocity,
							0.0,
							f32(rducc.window_width()) - b.scale.x)
			b.collider.origin = b.pos
		}
		
		//TC: RENDER
		rducc.background_clear(rducc.GRAY)
		rducc.draw_box({400.0, 500.0}, {64.0, 32.0}, colour = rducc.BLUE)
		rducc.draw_text("Hello", {400.0, 500.0}, 32)
		rducc.draw_circle({120.0, 232.0}, {32.0, 16.0}, colour = rducc.RED)
		for idx in 0..<bullet_count {
			b := bullets[idx]
			rducc.draw_circle(b.pos, b.scale)
		}
		rducc.draw_sprite(percy_texture, percy_entity.pos, percy_entity.scale)
		rducc.draw_sprite(enemy_texture, enemy_entity.pos, enemy_entity.scale)

		if debug_mode {
			debug.debug_entity_box(Entity, &bullets[0])
			debug_mode = false
		}

		rducc.commit()

		//TC: CLEANUP
		free_all(context.temp_allocator)
		prev_m_pos = m_pos

		//TC: RESET
		velocity = {}
	}
}

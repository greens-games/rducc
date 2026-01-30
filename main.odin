package main

import "core:encoding/entity"
import "core:strconv"
import "core:os/os2"
import "core:image"
import "core:image/png"
import "core:image/bmp"
import "core:mem"
import "core:mem/virtual"
import "core:fmt"

import stbi "vendor:stb/image"

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
	PAUSED,
}

Entity :: struct {
	pos:          [2]f32,
	scale:        [2]f32,
	collider:     pducc.Collider,
	direction:    i8,
	texture_hndl: i32,
	alive:        bool
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
	
	/////ARENAS ////////
	game_perm_arena: virtual.Arena 
	arena_err := virtual.arena_init_static(&game_perm_arena)
	assert(arena_err == nil)
	game_perm_arena_allocator := virtual.arena_allocator(&game_perm_arena)

	game_frame_arena: virtual.Arena 
	arena_err = virtual.arena_init_static(&game_frame_arena)
	assert(arena_err == nil)
	game_frame_arena_allocator := virtual.arena_allocator(&game_frame_arena)

	loaded_textures := make_dynamic_array([dynamic]rducc.Ducc_Texture, game_perm_arena_allocator)

	bullet_cap := 1
	bullets := make_slice([]Entity, bullet_cap, game_frame_arena_allocator)
	bullet_count := 0

	percy_image, percy_image_ok := image.load_from_bytes(#load("res/scuffed_percy.png"))
	percy_texture := rducc.sprite_load(percy_image.pixels.buf[:], percy_image.height, percy_image.width)
	append(&loaded_textures, percy_texture)
	percy_entity := entity_init({150, 150}, {32, 32}, len(loaded_textures) - 1)

	enemy_image, enemy_image_ok := image.load_from_bytes(#load("res/player_filled.png"))
	enemy_texture := rducc.sprite_load(enemy_image.pixels.buf[:], enemy_image.height, enemy_image.width)
	append(&loaded_textures, enemy_texture)
	enemy_entity := entity_init({185, 150}, {32, 32})

	ground_entity := entity_init({0, 0}, {f32(600), 96})

	m_pos_change := [2]f32{0.0, 0.0}
	prev_m_pos := rducc.window_mouse_pos()

	//Player specific fields
	velocity: [2]f32
	direction: i8 = 1
	jump_height := percy_entity.scale.y * 5
	move_speed := f32(250)
	jump_speed := f32(500)
	starting_height := percy_entity.pos.y
	gravity := f32(100)
	jumping := false

	debug_enitity: ^Entity = nil

	for !rducc.window_close() {
		//TC: INIT
		m_pos := rducc.window_mouse_pos()
		m_pos_change = m_pos - prev_m_pos

		dt := f32(rducc.time_delta_get())
		//TODO: Get some actual menu and pausing stuff going
		if rducc.window_is_key_pressed(.KEY_P) {
			game_state = game_state == .PLAYING ? .PAUSED : .PLAYING
		}

		if game_state == .PAUSED {
			continue
		}

		//TC: INPUT
		if rducc.window_is_mouse_button_down(.MOUSE_BUTTON_LEFT) {
			m_collider: pducc.Collider
			m_collider.kind = .RECT
			m_collider.origin = m_pos
			m_collider.scale = [2]f32{10, 10}
			if pducc.rect_collision(m_collider, percy_entity.collider) {
				//TODO: This can sometimes stop being detected when moving too fast
				percy_entity.pos += m_pos_change
			}
		}

		if rducc.window_is_key_pressed(.KEY_GRAVE_ACCENT) {
			debug_mode = !debug_mode
		}


		if rducc.window_is_key_pressed(.KEY_Q) {
				start_pos := f32(10 * direction) * f32((direction > 0) ? 2.5 : 1.5)
				bullet := entity_init(
					{percy_entity.pos.x  + start_pos, percy_entity.pos.y + percy_entity.scale.y/2},
					{16, 16},
					direction = direction
				)

				if bullet_count >= bullet_cap {
					bullet_count = 0
				}
				bullets[bullet_count] = bullet
				bullet_count += 1
		}

		if rducc.window_is_key_down(.KEY_D) {
			velocity.x += (move_speed * dt)
			direction = 1
		}

		if rducc.window_is_key_down(.KEY_A) {
			velocity.x -= (move_speed * dt)
			direction = -1
		}

		if rducc.window_is_key_pressed(.KEY_SPACE) {
			starting_height = percy_entity.pos.y
			jumping = true
		}

		if rducc.window_is_key_pressed(.KEY_R) {
			rducc.shader_load("res/vert_2d.glsl", "res/frag_texture.glsl")
			rducc.projection_set()
		}

		// TC: PHYSICS
			velocity.y -= (gravity * dt)
		if jumping {
			velocity.y += (jump_speed * dt)
		}
		if !jumping {
			if pducc.rect_collision(percy_entity.collider, ground_entity.collider) {
				velocity.y = 0
			}
		}
		for index in 0..<bullet_count {
			b := &bullets[index]
			b_velocity := (300 * dt * f32(b.direction))
			if pducc.rect_collision(b.collider, enemy_entity.collider) {
				b_velocity = 0.0
			}
			b.pos.x = clamp(b.pos.x + b_velocity,
							0.0,
							f32(rducc.window_width()) - b.scale.x)
			b.collider.origin = b.pos
		}
		percy_entity.pos += velocity
		percy_entity.collider.origin += velocity
		
		//TC: RENDER
		rducc.background_clear(rducc.GRAY)
		rducc.push_box({120.0, 232.0}, {32.0, 16.0}, colour = rducc.RED)
		for index in 0..<bullet_count {
			b := bullets[index]
			rducc.push_circle(b.pos, b.scale)
		}
		rducc.push_box({0, 0}, {f32(600), 96}, colour = rducc.BLACK)
		rducc.push_sprite(percy_texture, percy_entity.pos, percy_entity.scale, flip = {direction != 1, false})
		rducc.push_sprite(enemy_texture, enemy_entity.pos, enemy_entity.scale)

		if debug_mode {
			debug.debug_entity_box({0, f32(rducc.window_height())}, pducc.Collider, &ground_entity.collider, rducc.BLUE)
			debug.debug_entity_box({f32(rducc.window_width()), f32(rducc.window_height())}, pducc.Collider, &percy_entity.collider, rducc.GREEN)
		}

		rducc.commit()

		//TC: CLEANUP
		free_all(context.temp_allocator)
		prev_m_pos = m_pos

		//TC: RESET
		velocity = {}
		if percy_entity.pos.y >= jump_height + starting_height {
			jumping = false
		}
	}
}

entity_init :: proc(pos: [2]f32, scale: [2]f32, texture := -1, direction: i8 = 1) -> Entity {
	entity := Entity {
		pos       = pos,
		scale     = scale,
		texture_hndl = i32(texture),
		direction = direction,
		alive = true
	}

	collider  := pducc.Collider {
		kind   = .RECT,
		origin = entity.pos,
		scale  = entity.scale,
		radius = entity.scale.x,
	}
	entity.collider = collider
	return entity
}

package main

import "core:image"
import "core:image/png"
import "core:image/bmp"
import "core:mem"
import "core:mem/virtual"
import "core:fmt"
import "core:time"
import "core:strconv"
import "core:math/rand"
import "plumage"
import "peck"
import "quack"
import "demo_game"
import "constants"
import "../game_utils"


/**
Table of Contents:
	RESET
	CLEANUP
	RENDER
	INIT
*/

_ :: png
_ :: bmp

WINDOW_WIDTH  :: 980
WINDOW_HEIGHT :: 620
CELL_SIZE :: 32

Game_State :: enum {
	PLAYING,
	PAUSED,
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
	//Game Init
	plumage.init(WINDOW_WIDTH,WINDOW_HEIGHT,"plumage DEMO")
	debug_mode := false
	game_state: Game_State

	game_perm_arena: virtual.Arena 
	arena_err := virtual.arena_init_static(&game_perm_arena)
	assert(arena_err == nil)
	game_perm_arena_allocator := virtual.arena_allocator(&game_perm_arena)
	loaded_textures := make_dynamic_array([dynamic]plumage.Ducc_Texture, game_perm_arena_allocator)
	
	//TC: Level Init
	bullets := make_slice([]constants.Entity, constants.bullet_cap, game_perm_arena_allocator)
	entities: [500]constants.Entity
	load_textures(&loaded_textures)
	entity_count := load_level_1(entities[:], loaded_textures)

	m_pos_change := [2]f32{0.0, 0.0}
	prev_m_pos := plumage.window_mouse_pos()

	//Player specific fields
	player := &entities[0]

	debug_active_entity: i32 = -1

	frame_count := 0
	fps := 0
	fps_timer: time.Stopwatch

	quack.audio_init()
	quack.sound_load_from_file("./brackeys_platformer_assets/music/time_for_adventure.mp3")
	quack.sound_load_from_file("./brackeys_platformer_assets/sounds/jump.wav")
	quack.play_sound(0, true)

	//Pseudo anime stuffs
	sword_image, sword_ok := image.load_from_bytes(#load("./res/sword_test.png"))
	assert(sword_ok == nil)
	sword_anim := plumage.sprite_atlas_load(sword_image.pixels.buf[:], sword_image.width, sword_image.height, 32)
	anim_frame: i32 = 0
	anim_playing := false
	anim_frame_counter := 0
	anim_frame_time := 180 //number of frames or time in seconds?
	anim_frame_count := 3
	anim_timer: time.Stopwatch

	time.stopwatch_start(&fps_timer)
	for !plumage.window_close() {
		frame_count += 1
		//TC: INIT
		m_pos := plumage.window_mouse_pos()
		m_pos_change = m_pos - prev_m_pos

		dt := f32(plumage.time_delta_get())
		//TODO: Get some actual menu and pausing stuff going
		if plumage.window_is_key_pressed(.KEY_P) {
			game_state = game_state == .PLAYING ? .PAUSED : .PLAYING
			if game_state == .PAUSED {
				quack.play_sound(1)
				/* ma.sound_stop(&ma_sound) */
			} else if game_state == .PLAYING {
				quack.play_sound(1)
				/* ma.sound_start(&ma_sound) */
			}
		}

		/* if plumage.window_is_key_pressed(.KEY_R) {
			vs, vs_ok := os.read_entire_file_from_path("plumage/res/vert_2d.glsl", context.temp_allocator)
			assert(vs_ok == nil, "Vert shader didn't load from file")
			fs, fs_ok := os.read_entire_file_from_path("plumage/res/frag_texture.glsl", context.temp_allocator)
			assert(fs_ok == nil, "Frag shader didn't load from file")
			plumage.shader_load_from_mem(vs, fs)
			plumage.projection_set()
		} */

		if plumage.window_is_key_pressed(.KEY_J) {
			//play animation
			anim_playing = true
		}

		if plumage.window_is_mouse_button_pressed(.MOUSE_BUTTON_LEFT) {
			m_collider: peck.Collider
			m_collider.kind = .RECT
			m_collider.origin = m_pos
			m_collider.scale = [2]f32{10, 10}
			if debug_mode {
				for index in 0..<entity_count {
					thing := entities[index]
					if peck.rect_collision(m_collider, thing.collider) {
						debug_active_entity = i32(index)
						break
					} else {
						debug_active_entity = -1
					}
				}
			}
		}

		if plumage.window_is_key_pressed(.KEY_GRAVE_ACCENT) {
			debug_mode = !debug_mode
		}

		if game_state == .PLAYING {
			if demo_game.simulate_level(dt, player, entities[1:entity_count], bullets) {
				entity_count = hidden_level(entities[:], loaded_textures)
			}
		}
		
		//TC: RENDER
		if constants.curr_level == .V {
			plumage.background_clear({217, 89, 99, 255})
		} else {
			plumage.background_clear(plumage.GRAY)
		}
		for index in 0..<min(constants.bullet_count, constants.bullet_cap) {
			b := bullets[index]
			if b.alive {
				plumage.push_circle(b.pos, b.scale, plumage.RED)
			}
		}
		for index in 0..<entity_count {
			thing := entities[index]
			if !thing.alive {
				continue
			}
			switch thing.kind {
			case .PLAYER:
				plumage.push_sprite(loaded_textures[thing.texture_hndl], player.pos, player.scale, flip = {thing.direction != 1, false})
			case .ENEMY:
				plumage.push_sprite(loaded_textures[thing.texture_hndl], thing.pos, thing.scale)
			case .PLATFORM:
				plumage.push_box(thing.pos, thing.scale, plumage.BLACK)
			case .PROJECTILE:
			case .GOAL:
				plumage.push_box(thing.pos, thing.scale, plumage.YELLOW)
			case .PARTICLE:
				plumage.push_sprite(loaded_textures[thing.texture_hndl], thing.pos, thing.scale, colour = thing.colour)
			}
		}

		if constants.curr_level == .V {
			plumage.push_text("Will you be my Valentine?\n<3", {21 * CELL_SIZE, 3 * CELL_SIZE}, 32)
		}

		if debug_mode {
			draw_grid()
			for index in 0..<entity_count {
				entity := entities[index]
				switch entity.kind {
				case .PLAYER:
					plumage.push_box_lines(player.collider.origin, player.scale, plumage.BLUE)
				case .ENEMY:
					plumage.push_box_lines(entity.collider.origin, entity.scale, plumage.BLUE)
				case .PLATFORM:
					plumage.push_box_lines(entity.collider.origin, entity.scale, plumage.BLUE)
				case .PROJECTILE:
				case .GOAL:
				case .PARTICLE:
				}
			}

			//Make these little UI elements
			for index in 0..<entity_count {
				entity := entities[index]
				origin := entity.collider.origin
				point_size: f32 = 4
				plumage.push_box({origin.x - point_size, origin.y + entity.scale.y/2}, {point_size, point_size}, plumage.BLUE)
				plumage.push_box({origin.x + entity.scale.x/2, origin.y - point_size}, {point_size, point_size}, plumage.BLUE)
				plumage.push_box({origin.x + entity.scale.x, origin.y + entity.scale.y/2}, {point_size, point_size}, plumage.BLUE)
				plumage.push_box({origin.x + entity.scale.x/2, origin.y + entity.scale.y}, {point_size, point_size}, plumage.BLUE)
			}
			if debug_active_entity > -1 {
				/* thing := entities[debug_active_entity] */
				/* game_utils.debug_entity_box({thing.pos.x, thing.pos.y + thing.scale.y}, thing.collider, plumage.BLACK) */
			}
		}
		if anim_playing {
			anim_frame_counter += 1
			if anim_frame_counter%anim_frame_time == 0 {
				anim_frame += 1
			}
			if anim_frame > i32(anim_frame_count) {
				anim_playing = false
				anim_frame_counter = 0
				anim_frame = 0
			}
		}
		plumage.push_sprite_atlas(sword_anim, {21 * CELL_SIZE, 6 * CELL_SIZE}, {CELL_SIZE, CELL_SIZE}, {anim_frame, 0})
		plumage.push_text(fmt.tprintf("FPS: %d",fps),{0, 31 * CELL_SIZE}, 14)
		plumage.push_text(fmt.tprintf("Frame Time: %.2f(ms)", dt * 1000),{0, 30 * CELL_SIZE}, 14)

		plumage.commit()

		//TC: CLEANUP
		free_all(context.temp_allocator)
		prev_m_pos = m_pos


		if time.stopwatch_duration(fps_timer) >= time.Second {
			time.stopwatch_reset(&fps_timer)
			fps = frame_count
			frame_count = 0
			time.stopwatch_start(&fps_timer)
		}
		quack.update_audio()
	}
}

entity_init :: proc(pos: [2]f32, scale: [2]f32, kind: constants.Entity_Kind, texture := -1, direction: i8 = 1) -> constants.Entity {
	entity := constants.Entity {
		kind         = kind,
		pos          = pos,
		scale        = scale,
		texture_hndl = i32(texture),
		direction    = direction,
		alive        = true,
		h_speed      = 250,
		v_speed      = 250,
	}

	collider  := peck.Collider {
		kind   = .RECT,
		origin = entity.pos,
		scale  = entity.scale,
		radius = entity.scale.x,
	}
	entity.collider = collider
	return entity
}

draw_grid :: proc() {
	rows: f32 = 50
	cols: f32 = 50

	buf := [?]byte{0, 1}
	for r in 1..=rows {
		plumage.push_line({0.0, 32 * r}, {cols * 32, 32 * r}, plumage.RED)
	}
	for c in 1..=cols {
		plumage.push_line({32 * c, 0.0}, {c * 32, 32 * rows}, plumage.RED)
	}

	for r in 1..=rows {
		plumage.push_text(strconv.write_int(buf[:], i64(r), 10), {0.0, 32 * r}, 10)
	}
	for c in 1..=cols {
		plumage.push_text(strconv.write_int(buf[:], i64(c), 10), {32 * c, 0.0}, 10)
	}
}

hit_platform :: proc(collidee: peck.Collider, velocity: [2]f32, things: []constants.Entity, kind: constants.Entity_Kind = .PLATFORM) -> (bool, constants.Entity) {
	_collidee := collidee
	_collidee.origin += velocity
	for thing in things {
		if thing.kind == kind && peck.rect_collision(_collidee, thing.collider) {
			return true, thing
		}
	}
	return false, {}
}

load_textures :: proc(loaded_textures: ^[dynamic]plumage.Ducc_Texture) {
	percy_image, percy_image_ok := image.load_from_bytes(#load("res/scuffed_percy.png"))
	percy_texture := plumage.sprite_load(percy_image.pixels.buf[:], percy_image.width, percy_image.height)
	append(loaded_textures, percy_texture)

	enemy_image, enemy_image_ok := image.load_from_bytes(#load("res/player_filled.png"))
	enemy_texture := plumage.sprite_load(enemy_image.pixels.buf[:], enemy_image.width, enemy_image.height)
	append(loaded_textures, enemy_texture)

	heart_image, heart_image_ok := image.load_from_bytes(#load("res/Heart.png"))
	heart_texture := plumage.sprite_load(heart_image.pixels.buf[:], heart_image.width, heart_image.height)
	append(loaded_textures, heart_texture)
}

load_level_1 :: proc(entities: []constants.Entity, loaded_textures: [dynamic]plumage.Ducc_Texture) -> (entity_count: i32) {
	percy_entity := entity_init({150, 4 * 32}, {32, 32}, .PLAYER, 0)

	enemy_entity := entity_init({185, 4 * 32}, {32, 32}, .ENEMY, 1)

	percy_entity.health = 100
	entities[entity_count] = percy_entity
	entity_count += 1

	enemy_entity.health = 50
	entities[entity_count] = enemy_entity
	entity_count += 1

	entities[entity_count] = entity_init({0, 0}, {20 * CELL_SIZE, 3 * CELL_SIZE}, .PLATFORM)
	entities[entity_count].traits = .STATIC
	entity_count += 1

	entities[entity_count] = entity_init({4 * 32, 5 * 32}, {2 * CELL_SIZE, 0.5 * CELL_SIZE}, .PLATFORM)
	entities[entity_count].traits = .MOVEABLE
	waypoints := make_slice([]constants.Cell, 2)
	waypoints[0] = {3 * 32, 5 * 32}
	waypoints[1] = {15 * 32, 5 * 32}
	entities[entity_count].waypoints = waypoints
	entity_count += 1

	entities[entity_count] = entity_init({20 * 32, 0 * 32}, {9 * CELL_SIZE, 8 * CELL_SIZE}, .PLATFORM)
	entities[entity_count].traits = .STATIC
	entity_count += 1

	entities[entity_count] = entity_init({19 * CELL_SIZE, 6 * CELL_SIZE}, {CELL_SIZE, 0.5 * CELL_SIZE}, .PLATFORM)
	entities[entity_count].traits = .STATIC
	entity_count += 1

	entities[entity_count] = entity_init({0, 96}, {32, 32}, .PLATFORM)
	entities[entity_count].traits = .STATIC
	entity_count += 1

	entities[entity_count] = entity_init({4 * CELL_SIZE, 4 * CELL_SIZE}, {16, 16}, .GOAL)
	entity_count += 1
	return
}

hidden_level :: proc(entities: []constants.Entity, loaded_textures: [dynamic]plumage.Ducc_Texture) -> (entity_count: i32) {
	percy_entity := entity_init({150, 4 * 32}, {32, 32}, .PLAYER, 0)

	percy_entity.health = 100
	entities[entity_count] = percy_entity
	entity_count += 1

	for i in 0..<60 {
		start_x := f32(rand.uint_range(2, 42))
		start_y := f32(rand.uint_range(5, 17))
		entities[entity_count] = entity_init({start_x * CELL_SIZE, start_y * CELL_SIZE}, {CELL_SIZE, CELL_SIZE}, .PARTICLE, 2)
		entities[entity_count].colour = plumage.WHITE
		entity_count += 1
	}

	entities[entity_count] = entity_init({0, 0}, {20 * CELL_SIZE, 3 * CELL_SIZE}, .PLATFORM)
	entity_count += 1
	return
}

audio_thread :: proc() {
	quack.audio_init()
	quack.sound_load_from_file("./brackeys_platformer_assets/music/time_for_adventure.mp3")
	quack.sound_load_from_file("./brackeys_platformer_assets/sounds/jump.wav")
	quack.play_sound(0, true)
	for {
	}
}

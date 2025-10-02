package main

import "core:sys/posix"
import "core:math/linalg"
import "rducc"
import "pducc"
import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"

Entity_Kind :: enum {
	PLAYER,
	ENEMY,
	WALL,
}

W_HEIGHT :: 620
W_WIDTH  :: 980

ROWS :: 20
COLS :: 20

Game_Context :: struct {
	entities:     [100]Entity,
	entity_count: i32,
	grid:         [ROWS][COLS]Cell,
}

//TODO: Decide if I want to move to a grid based map system;
//This would mainly be for positioning and not necessarily moving, we can also try to standardize distances
Entity :: struct {
	id:              i32,
	kind:            Entity_Kind,
	pos:          [3]f32,
	curr_cell:    [2]u32,
	scale:        [2]f32,
	velocity:     [2]f32,
	direction:    [2]f32,
	rotation:        f32,
	fire_rate_cd:    f32,
	fire_rate:       f32,
	bullet_range:    f32,
	to_free:         bool,
	collider:        pducc.Collider,
}

Cell :: struct {
	occupiers: [3]i32,
}


/* 
curr_rotation = math.to_degrees(math.atan2((game_mem.player.y ) - m_pos.y, (game_mem.player.x ) - m_pos.x))
*/

SPRITE_SCALE :: [2]f32{32.0, 32.0}
debug_draw := false

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
	/* shape_test() */
	/* rducc.renderer_sprite_load("res/scuffed_percy.png") */
}

game_entity_init :: proc(ctx: ^Game_Context, pos: [3]f32, collider: bool, kind: Entity_Kind) {
	guy: Entity
	guy.pos = pos
	guy.scale = SPRITE_SCALE
	if collider {
		guy.collider.origin = guy.pos.xy
		guy.collider.scale = SPRITE_SCALE
		guy.collider.kind = .RECT
	}
	guy.fire_rate = 0.5
	guy.kind = kind
	ctx.entities[ctx.entity_count] = guy
	ctx.entity_count += 1
}

game_context_init :: proc() -> Game_Context{
	ctx: Game_Context
	for row, r in ctx.grid {
		for col, c in ctx.grid {
			ctx.grid[r][c] = {
				{-1, -1, -1}
			}
		}
	}
	return ctx
}

pos_to_cell :: proc(pos: [3]f32) -> [2]u32 {
	return {u32(math.round_f32(pos.x/SPRITE_SCALE.x)), u32(math.round_f32(pos.y/SPRITE_SCALE.y))}
}

run :: proc() {
	game_ctx := game_context_init()
	rducc.window_open(980,620,"RDUCC DEMO")
	rducc.renderer_init()

	rducc.shader_load("res/vert_2d.glsl", "res/frag_primitive.glsl")
	rducc.shader_load("res/vert_2d.glsl", "res/frag_texture.glsl")
	rducc.shader_load("res/vert_2d.glsl", "res/circle_shader.glsl")
	rducc.shader_load("res/vert_grid.glsl", "res/grid.glsl")

	rducc.renderer_sprite_load("res/scuffed_percy.png")
	bullets := make_dynamic_array([dynamic]Entity)
	guy: Entity
	//TODO:Find a way to do "canonical" positioning (i.e position by meters and move m/s rather than pixels)game_ctx.
	curr_rotation: f32 = 0.
	game_entity_init(&game_ctx, {500.0, 200.0, 0.0}, true, .PLAYER)
	player := &game_ctx.entities[0]

	game_entity_init(&game_ctx, {150.0, 150.0, 0.0}, true, .ENEMY)


	for !rducc.window_close() {
		//NOTE: This porbably shouldn't stay find a better way to handle freeing bullets
		bullets_to_free := make_dynamic_array([dynamic]Entity, context.temp_allocator)

		//TC: INIT
		m_pos := rducc.window_mouse_pos()
		curr_rotation_radians := math.atan2((player.pos.y ) - m_pos.y, (player.pos.x ) - m_pos.x)
		curr_rotation_degrees := math.to_degrees(curr_rotation_radians)
		dt := rducc.time_delta_get()
		player.fire_rate_cd -= f32(dt)
		player.rotation = curr_rotation_degrees

		//TC: INPUT
		if rducc.window_is_mouse_button_down(.MOUSE_BUTTON_LEFT) && player.fire_rate_cd <= 0 {
			//TODO: We need a better way to handle bullets that doesn't allocate memory every time we click
			//Because append() will allocate memory
			bullet: Entity
			bullet.pos = player.pos
			bullet.scale = {8,8}
			bullet.rotation = player.rotation
			bullet.collider = {
				origin = bullet.pos.xy,
				scale = bullet.scale,
			}
			dist: [2]f32 = m_pos - player.pos.xy
			bullet.direction = linalg.vector_normalize(dist)
			append(&bullets, bullet)
			player.fire_rate_cd = player.fire_rate
		}

		if rducc.window_is_key_down(.KEY_W) {
			player.velocity.y += f32(100. * dt)
		}

		if rducc.window_is_key_down(.KEY_A) {
			player.velocity.x -= f32(100. * dt)
		}

		if rducc.window_is_key_down(.KEY_S) {
			player.velocity.y -= f32(100. * dt)
		}

		if rducc.window_is_key_down(.KEY_D) {
			player.velocity.x += f32(100. * dt)
		}

		if rducc.window_is_key_pressed(.KEY_GRAVE_ACCENT) {
			debug_draw = !debug_draw
		}

		if rducc.window_is_key_pressed(.KEY_Q) {

		}

		// TC: PHYSICS
		//TODO:THIS IS GOING TO HAVE TO CHANGE ALOT
		for &bullet in bullets {
			bullet.velocity += bullet.direction * 250. * f32(dt)
			for idx in 1..<game_ctx.entity_count{
				e := game_ctx.entities[idx]
				if pducc.rect_collision({
					origin = bullet.collider.origin + bullet.velocity,
					scale = bullet.collider.scale
				},
				e.collider) {
					bullet.to_free = true
				}
			}
			if bullet.pos.x + bullet.velocity.x >= (COLS - 1) * SPRITE_SCALE.x || bullet.pos.x + bullet.velocity.x <= 0.0 {
				bullet.velocity.x *= -1.0
				bullet.direction.x *= -1.0
			}

			if bullet.pos.y + bullet.velocity.y >= (ROWS - 1) * SPRITE_SCALE.y || bullet.pos.y + bullet.velocity.y <= 0.0 {
				bullet.velocity.y *= -1.0
				bullet.direction.y *= -1.0
			}
			if debug_draw {
				a := 1
				_ = a
			}
			bullet.pos.x += bullet.velocity.x
			bullet.pos.y += bullet.velocity.y

			bullet.collider.origin += bullet.velocity
			bullet.velocity = {}
			if bullet.pos.x > f32(rducc.window_width()) || bullet.pos.x < 0. {
				bullet.to_free = true
			} else if bullet.pos.y > f32(rducc.window_height()) || bullet.pos.y < 0. {
				bullet.to_free = true
			}
		}

		if pducc.rect_collision({
			origin = player.collider.origin + player.velocity, 
			scale = player.collider.scale
			}, 
			game_ctx.entities[1].collider) {
			player.velocity = {}
		}
		player.pos = clamp_pos(player.pos, player.velocity)
		player.collider.origin += player.velocity
		
		player.velocity = {}

		//TC: Assign Grid Cells
		for idx in 0..< game_ctx.entity_count {
			entity := &game_ctx.entities[idx]
			cell_pos := pos_to_cell(entity.pos)
			curr_pos := entity.curr_cell
			col := cell_pos.x
			row := cell_pos.y
			game_ctx.grid[curr_pos.y][curr_pos.x].occupiers[0] = -1
			game_ctx.grid[row][col].occupiers[0] = entity.id
			entity.curr_cell = {col, row}
		}

		//TC: RENDER
		rducc.renderer_background_clear(rducc.GRAY)

		for row, r in game_ctx.grid {
			for col, c in row {
				if col.occupiers[0] != -1 {
					colour: rducc.Colour
					colour = {255,255,255,125}
					rducc.renderer_box({f32(c) * SPRITE_SCALE.x, f32(r) * SPRITE_SCALE.y, 0.0}, SPRITE_SCALE, colour = colour)
				}
			}
		}

		for &bullet in bullets {
			rducc.renderer_box(bullet.pos, bullet.scale, bullet.rotation, rducc.BLACK)
			if debug_draw {
				rducc.renderer_box_lines(bullet.pos, bullet.scale, bullet.rotation, rducc.GREEN)
			}
		}

		for idx in 0..<game_ctx.entity_count {
			e := game_ctx.entities[idx]
			switch e.kind {
			case .PLAYER:
				rducc.renderer_sprite_draw(e.pos, e.scale, e.rotation, rducc.WHITE)
			case.ENEMY:
				rducc.renderer_box(e.pos, e.scale, e.rotation, rducc.BLUE)
			case.WALL:
				rducc.renderer_box(e.pos, e.scale, e.rotation, rducc.BLUE)
			}
			if debug_draw {
				rducc.renderer_box_lines({e.collider.origin.x, e.collider.origin.y, 0.0}, e.collider.scale, e.rotation, rducc.GREEN)
			}
		}

		rducc.renderer_circle_vertices({50.,0., 0.0}, 16.0, 0., rducc.BLUE)
		rducc.renderer_circle_shader({0.0,0.0,0.0}, {32.0, 32.0}, 0., rducc.BLUE)
		/* rducc.renderer_grid_draw(rducc.GREEN) */
		//bath render (rducc.commit()?)


		//TC: CLEANUP
		//NOTE: This is really bad and should probably not stay, find a better way to free bullets
		for bullet, i in bullets {
			if bullet.to_free {
				append(&bullets_to_free, bullet)
				ordered_remove(&bullets, i)
			}
		}
		free_all()
	}
}

clamp_pos :: proc(pos: [3]f32, velocity: [2]f32) -> [3]f32 {
	_pos := pos
	_pos.x = clamp(_pos.x + velocity.x, 0.0, (COLS - 1.0) * SPRITE_SCALE.x)
	_pos.y = clamp(_pos.y + velocity.y, 0.0, (ROWS - 1.0) * SPRITE_SCALE.y)
	return _pos
}

shape_test :: proc() {
	rducc.window_open(980,620,"RDUCC DEMO")
	rducc.renderer_init()
	rducc.shader_load("res/vert_single_shape.glsl", "res/frag_primitive.glsl")
	click_cd_rate := 0.5
	click_cd := 0.0
	for !rducc.window_close() {
		dt := rducc.time_delta_get()
		click_cd -= dt
		if rducc.window_is_mouse_button_down(.MOUSE_BUTTON_LEFT) && click_cd <= 0 {
			click_cd = click_cd_rate
			
		}
	}
}


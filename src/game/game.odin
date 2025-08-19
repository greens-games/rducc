package src

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "../../lib"


Game_State :: enum {
	MENU,
	PLAYING
}

Entity :: struct {
	pos:          [3]f32,
	velocity:     [3]f32,
	direction:    [3]f32,
	rotation:     f32,
	fire_rate_cd: f32,
	fire_rate:    f32,
	bullet_range: f32,
	to_free:      bool,
}

Game_Mem :: struct {
	entities:     [100]Entity,
	entity_count: int,
	bullets:      [dynamic]Entity,
	game_state:   Game_State,
}

init :: proc() -> ^Game_Mem {
	lib.rducc_window_open(980,620,"RDUCC DEMO")
	lib.rducc_renderer_init()
	lib.rducc_shader_load("res/vert_2d.glsl", "res/frag_primitive.glsl")

	game_mem: ^Game_Mem
	game_mem = new(Game_Mem)

	game_mem.bullets = make_dynamic_array([dynamic]Entity)
	guy: Entity
	//TODO:Find a way to do "canonical" positioning (i.e position by meters and move m/s rather than pixels)
	guy.pos = {f32(lib.ctx.window_width)/2.,f32(lib.ctx.window_height)/2.,0}
	guy.fire_rate = 0.5
	game_mem.entities[0] = guy
	game_mem.entity_count += 1
	return game_mem
}

update :: proc(game_mem: ^Game_Mem) {
	//NOTE: This porbably shouldn't stay find a better way to handle freeing bullets
	bullets_to_free := make_dynamic_array([dynamic]Entity, context.temp_allocator)

	m_pos := lib.rducc_window_mouse_pos()
	guy := game_mem.entities[0]
	guy.rotation = math.to_degrees(math.atan2((guy.pos.y ) - m_pos.y, (guy.pos.x ) - m_pos.x))
	dt := lib.rducc_time_delta_get()
	guy.fire_rate_cd -= f32(dt)
	if lib.rducc_window_is_mouse_button_down(.MOUSE_BUTTON_LEFT) && guy.fire_rate_cd <= 0 {
		bullet: Entity
		bullet.pos = guy.pos
		bullet.rotation = guy.rotation
		dist: [3]f32 = {m_pos.x, m_pos.y, 0} - guy.pos
		bullet.direction = linalg.vector_normalize(dist)
		append(&game_mem.bullets, bullet)
		guy.fire_rate_cd = guy.fire_rate
	}

	if lib.rducc_window_is_key_down(.KEY_A) {
		guy.velocity.x -= f32(100. * dt)
	}
	if lib.rducc_window_is_key_down(.KEY_D) {
		guy.velocity.x += f32(100. * dt)
	}

	if lib.rducc_window_is_key_down(.KEY_S) {
		guy.velocity.y -= f32(100. * dt)
	}

	if lib.rducc_window_is_key_down(.KEY_W) {
		guy.velocity.y += f32(100. * dt)
	}
	guy.pos += guy.velocity
	guy.velocity = {}
	lib.rducc_renderer_background_clear(lib.GRAY)
	for &bullet in game_mem.bullets {
		bullet.velocity += bullet.direction * 250. * f32(dt)
		bullet.pos += bullet.velocity
		bullet.velocity = {}
		lib.rducc_renderer_box({bullet.pos, {8,16,0}, bullet.rotation}, {lib.BLACK})
		if bullet.pos.x > f32(lib.rducc_window_width()) || bullet.pos.x < 0. {
			bullet.to_free = true
			} else if bullet.pos.y > f32(lib.rducc_window_height()) || bullet.pos.y < 0. {
				bullet.to_free = true
		}
	}

	//NOTE: This is really bad and should probably not stay, find a better way to free game_mem.bullets
	for bullet, i in game_mem.bullets {
		if bullet.to_free {
			append(&bullets_to_free, bullet)
			ordered_remove(&game_mem.bullets, i)
		}
	}
	lib.rducc_renderer_box({guy.pos, {16,16,0}, guy.rotation}, {lib.BLUE})
	free_all()
}

draw :: proc(game_mem: ^Game_Mem) {
}
 
clean_up :: proc() {
}

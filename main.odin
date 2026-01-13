package main

import "core:image"
import "core:image/png"
import "core:image/bmp"
import fs "vendor:fontstash"
import stbi "vendor:stb/image"
import "debug"

import "core:time"
import "core:hash"
import "rducc"
import "pducc"

import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"

W_HEIGHT :: 620
W_WIDTH  :: 980

ROWS :: 20
COLS :: 20

Entity_Kind :: enum {
	TOKEN,
}

Widget_Kind :: enum {
	BUTTON,
	TEXT_BOX,
	CHECK_BOX,
}

/*
RELATIVE = percentage relative to window size
ABSOLUTTE = x,y as is
*/
Position_Kind :: enum {
	RELATIVE,
	ABSOLUTE,
}

Game_Context :: struct {
	entities:     [100]Entity,
	entity_count: i32,
	grid:         [ROWS][COLS]Cell,
}

Entity :: struct {
	id:         i32,
	kind:       Entity_Kind,
	texture:    ^rducc.Ducc_Texture,
	pos:        [3]f32,
	curr_cell:  [2]u32,
	rotation:   f32,
	scale:      [2]f32,
	collider:   pducc.Collider,
}

Widget :: struct {
	id:        i32,
	kind:      Widget_Kind,
	pos:       [3]f32,
	rotation:  f32,
	scale:     [2]f32,
	collider:  pducc.Collider,
	active:    bool,
	hot:       bool,
}

hot_widget: i32 = -1
active_widget: i32 = -1

Cell :: struct {
	occupiers: [3]i32,
}

SPRITE_SCALE :: [2]f32{32.0, 32.0}
BASE_SCALE :: [2]f32{16.0, 16.0}
debug_draw := false

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
	/* test() */
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
	rducc.init()
	r_group1 := rducc.render_group_create()
	curr_rotation: f32 = 0.

	mouse_entity: Entity
	mouse_entity.scale = {4.0, 4.0}
	mouse_entity.id = 0
	mouse_entity.collider = {}
	mouse_entity.collider.scale = {4.0, 4.0}
	mouse_entity.collider.kind = .RECT
	mouse_entity.collider.radius = 4.0

	//TODO: Decide how we want to handle storing textures
	//Can be:
	//a static array     (entity holds id), 
	//an arena allocator (entity holds pointer to texture), 
	percy_image, image_ok := image.load_from_bytes(#load("res/scuffed_percy.png"))
	percy_texture := rducc.sprite_load(percy_image.pixels.buf[:], percy_image.height, percy_image.width)


	//TODO:This does not load the generated font correctly (maybe see karl2d for ttf loading)
	font_image, font_image_ok := image.load_from_bytes(#load("res/Font3.bmp"))
	assert(font_image_ok == nil)
	my_font := rducc.sprite_atlas_load(font_image.pixels.buf[:], font_image.height, font_image.width, 32)


	width, height, channels: i32
	stbi.set_flip_vertically_on_load(1)
	data := stbi.load("res/Font3.bmp", &width, &height, &channels, 4)
	my_font2 := rducc.font_load(data[:width * height], int(height), int(width), 32, 32)
	rducc.ctx.default_font = rducc.font_load(data[:width * height], int(height), int(width), 32, 32)

	percy_entity: Entity
	percy_entity.texture = &percy_texture
	percy_entity.scale = SPRITE_SCALE
	percy_entity.pos = {150.0, 150.0, 1.0}
	percy_entity.id = 0
	percy_entity.collider = {}
	percy_entity.collider.scale = {4.0, 4.0}
	percy_entity.collider.kind = .RECT
	percy_entity.collider.radius = 4.0

	colour := rducc.GREEN
	m_pos_change := [2]f32{0.0, 0.0}
	prev_m_pos := rducc.window_mouse_pos()

	r_group2 := rducc.render_group_create()
	for !rducc.window_close() {
		//TC: INIT
		active_widget = -1
		m_pos := rducc.window_mouse_pos()
		m_pos_change = m_pos - prev_m_pos

		dt := rducc.time_delta_get()

		//TC: INPUT
		if rducc.window_is_mouse_button_pressed(.MOUSE_BUTTON_LEFT) {
			fmt.println("M_POS_CHANGE: ", m_pos_change)
		}
		if rducc.window_is_key_pressed(.KEY_GRAVE_ACCENT) {
			debug_draw = !debug_draw
		}
		if rducc.window_is_key_pressed(.KEY_Q) {
		}

		if rducc.window_is_key_pressed(.KEY_R) {
			rducc.shader_load("res/vert_2d.glsl", "res/frag_texture.glsl")
			rducc.projection_set()
		}

		// TC: PHYSICS
		mouse_entity.pos = {m_pos.x - 2, m_pos.y - 2, 0.0}
		mouse_entity.collider.origin = {m_pos.x - 2, m_pos.y - 2}
		
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
		rducc.background_clear(rducc.GRAY)
		/* rducc.draw_circle({m_pos.x, m_pos.y, 0.0}, {4.0,4.0}, colour = rducc.RED) */
		/* rducc.draw_text(rducc.ctx.default_font, "Hello World!", {600.0, 500.0}, 16) */
		rducc.draw_text(rducc.ctx.default_font, "Hello", {400.0, 500.0}, 16)
		/* rducc.draw_circle({200.0,200.0,0.0}, {32.0, 32.0}, colour = rducc.RED) */
		/* rducc.draw_box({100.0,100.0,0.0}, {32.0, 32.0}) */
		rducc.draw_sprite(percy_texture, percy_entity.pos, percy_entity.scale)
		rducc.commit()

		//TC: CLEANUP
		//NOTE: This is really bad and should probably not stay, find a better way to free bullets
		free_all()
		prev_m_pos = m_pos
	}
}

clamp_pos :: proc(pos: [3]f32, velocity: [2]f32) -> [3]f32 {
	_pos := pos
	_pos.x = clamp(_pos.x + velocity.x, 0.0, (COLS - 1.0) * SPRITE_SCALE.x)
	_pos.y = clamp(_pos.y + velocity.y, 0.0, (ROWS - 1.0) * SPRITE_SCALE.y)
	return _pos
}

/*
RELATIVE = percentage relative to window size
ABSOLUTTE = x,y as is
*/
widget_button :: proc(text: string, button_pos, button_size, mouse_pos: [2]f32, pos_kind: Position_Kind) -> bool {
	h := hash.ginger16(transmute([]byte)text)
	clicked := false
	_pos := button_pos
	switch pos_kind {
	case .RELATIVE:
		assert(button_pos.x <= 100 && button_pos.y <= 100)
		assert(button_pos.x >= 0 && button_pos.y >= 0)
		_pos.x = f32(rducc.ctx.window_width)  * (button_pos.x * 0.01) - button_size.x
		_pos.y = f32(rducc.ctx.window_height) * (button_pos.y * 0.01) - button_size.y
	case .ABSOLUTE:
	}
	mouse_collider: pducc.Collider 
	mouse_collider = {}
	mouse_collider.scale = {4.0, 4.0}
	mouse_collider.kind = .RECT
	mouse_collider.origin = mouse_pos

	button_collider: pducc.Collider = {}
	button_collider.origin = _pos
	button_collider.scale = button_size
	button_collider.kind = .RECT
	colour := rducc.BLUE

	if pducc.rect_collision(mouse_collider, button_collider) {
		hot_widget = i32(h)
		colour = rducc.GREEN
		if rducc.window_is_mouse_button_pressed(.MOUSE_BUTTON_LEFT) {
			active_widget = i32(h)
			clicked = true
		}
	}

	rducc.draw_text(rducc.ctx.default_font, text, _pos, 16, rducc.WHITE)
	rducc.draw_box({_pos.x, _pos.y, 0.0}, button_size, colour = colour)

	return clicked
}

debug_profile :: proc(a: rawptr, msg: string) {
	start := time.now()
	_a := cast(proc()) a
	_a()
	end := time.now()
	fmt.printfln("Time taken to draw box: %d", (end._nsec - start._nsec))
}

test :: proc() {
	result, ok := os.read_entire_file_from_filename("res/minecraft-font/MinecraftRegular-Bmg3.otf")
	fmt.printfln("%d", size_of(rducc.Vertex))
}

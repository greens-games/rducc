package demo_game

import "../plumage"
import "../peck"
import "../quack"
import "../constants"

import "core:math/rand"

//TODO: Need to take another crack at this it's not great
//Params need to be overhauled and actual logic needs cleaning
simulate_level :: proc(dt: f32, player: ^constants.Entity, entities: []constants.Entity, bullets: []constants.Entity) -> bool {
	jump_time: f32 = 0.3
	move_speed := f32(250)
	jump_speed := f32(500)
	gravity := f32(250)
	jump_height := player.scale.y * 3
	starting_height := player.pos.y
	//TC: Player Input
	if plumage.window_is_key_pressed(.KEY_Q) {
		start_pos := f32(10 * player.direction) * f32((player.direction > 0) ? 2.5 : 1.5)
		bullet := entity_init(
			{player.pos.x  + start_pos, player.pos.y + player.scale.y/2},
			{16, 16},
			.PROJECTILE,
			direction = player.direction
		)
		bullet.damage = 10

		bullets[constants.bullet_count%(constants.bullet_cap -1)] = bullet
		constants.bullet_count += 1
	}

	if plumage.window_is_key_down(.KEY_D) {
		player.velocity.x += (player.h_speed * dt)
		player.direction = 1
	}

	if plumage.window_is_key_down(.KEY_A) {
		player.velocity.x -= (player.h_speed * dt)
		player.direction = -1
	}

	player_hit, thing_player_hit := hit_platform(player^.collider, player.velocity, entities)
	if  player_hit {
		player.velocity.x = 0
	}

	if plumage.window_is_key_pressed(.KEY_SPACE) && constants.jumps > 0 {
		starting_height = player.pos.y
		constants.jumps -= 1
		constants.jumping = true
		quack.play_sound(1)
	}

	if constants.jumping {
		player.velocity.y += (jump_speed * dt)
		constants.curr_jump_time += dt
		if player_hit {
			player.velocity.y = 0
			constants.jumping = false
			constants.curr_jump_time = 0
		}
	}

	//Player physics
	player.velocity.y -= (gravity * dt)
	hit, thing_hit := hit_platform(player.collider, player.velocity, entities)
	if hit {
		if thing_hit.traits == .MOVEABLE {
			if player.velocity.x == 0 {
				player.velocity.x = 200 * dt * f32(thing_hit.direction)
			}
		}
		player.velocity.y = 0
		constants.jumps = 1
	}
	goal_hit, _ := hit_platform(player.collider, player.velocity, entities, .GOAL)
	if goal_hit {
		constants.curr_level = .V
		return true
	}
	player.pos.x = clamp(player.pos.x + player.velocity.x,
		0.0,
		f32(plumage.window_width()) - player.scale.x)
	player.pos.y += player.velocity.y

	player.collider.origin.x = clamp(player.collider.origin.x + player.velocity.x,
		0.0,
		f32(plumage.window_width()) - player.collider.scale.x)
	player.collider.origin.y += player.velocity.y

	//All other entities physics
	for &entity in entities {
		switch entity.kind {
		case .PLAYER:
		case .ENEMY:
			entity.velocity.y -= (gravity * dt)
			hit, thing_hit := hit_platform(entity.collider, entity.velocity, entities)
			if hit {
				entity.velocity.y = 0
			}
			entity.pos.y += entity.velocity.y
			entity.collider.origin.y += entity.velocity.y
		case .PROJECTILE:
		case .PLATFORM:
			if entity.traits == .MOVEABLE {
				waypoints := entity.waypoints

				next_waypoint := entity.waypoints[(entity.curr_waypoint + 1)%i32(len(entity.waypoints))]
				dir_x := next_waypoint.col - entity.pos.x > 0 ? 1 : -1

				//TODO: This should use velocity eventually
				entity.pos.x += 200 * dt * f32(dir_x)
				entity.collider.origin.x += 200 * dt * f32(dir_x)
				if dir_x > 0 && entity.pos.x > next_waypoint.col {
					entity.curr_waypoint += 1
				} else if dir_x < 0 && entity.pos.x < next_waypoint.col {
					entity.curr_waypoint += 1
				}
				if entity.curr_waypoint == i32(len(entity.waypoints)) {
					entity.curr_waypoint = 0
				}
				entity.direction = i8(dir_x)
			}
		case .GOAL:
		case .PARTICLE:
			entity.pos.y += 250 * dt
			entity.colour.a -= 1
			if entity.colour.a <= 0 {
				start_x := f32(rand.uint_range(2, 42))
				start_y := f32(rand.uint_range(5, 17))
				entity.pos = {start_x * constants.CELL_SIZE, start_y * constants.CELL_SIZE}
				entity.colour.a = 255
			}
		}
	}

	//TC: Bullet logic
	for index in 0..<min(constants.bullet_count, constants.bullet_cap) {
		b := &bullets[index]
		if b.alive {
			b_velocity := (300 * dt * f32(b.direction))
			//TODO: we are doing this entity iteration in a lot of places we should cosolodate it more
			for &entity in entities {
				if peck.rect_collision(b.collider, entity.collider) && entity.alive {
					b.alive = false
					if entity.kind == .ENEMY {
						entity.health -= b.damage
						if entity.health <= 0 {
							entity.alive = false
						}
					}
				}
			}
			if b.pos.x + b_velocity >= f32(plumage.window_width()) || b.pos.x + b_velocity <= 0.0 {
				b.alive = false
			}
			b.pos.x += b_velocity
			b.collider.origin = b.pos
		}
	}

	//TC: RESET
	player.velocity = {}

	if constants.curr_jump_time >= jump_time{
		constants.jumping = false
		constants.curr_jump_time = 0
	}
	return false
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

render_level :: proc() {
}

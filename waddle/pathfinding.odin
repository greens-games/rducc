package waddle

import "core:math"
import "core:fmt"

Node :: struct {
	id: i32,
	data: [2]i32,
	parent_hndl: i32,
	dist: i32,
}

dijkstras_bfs :: proc(start, goal: [2]i32, entity: ^Entity) {
	unvisited := make_dynamic_array([dynamic]Node, context.temp_allocator)
	visited := make_dynamic_array([dynamic]Node, context.temp_allocator)
	for r := 0; r < len(game_state.grid); r += 1 {
		for c := 0; c < len(game_state.grid[0]); c += 1 {
			//TODO: This works for not going to the same place but sometimes entities just disappear?
			if !resolve_contains([2]i32{i32(r), i32(c)}, game_state.resolves) {
				temp_node: Node
				temp_node.data = {i32(c),i32(r)}
				temp_node.parent_hndl = -1
				temp_node.dist = 9999
				if i32(c) == start.x && i32(r) == start.y {
					temp_node.dist = 0
				}
				append(&unvisited, temp_node)
			}
		}
	}

	for i := 0; i < len(unvisited); {
		shorest_index := find_shortest_dist(unvisited)
		temp_point := unvisited[shorest_index]
		temp_point.id = i32(len(visited))
		unordered_remove(&unvisited, shorest_index)
		append(&visited, temp_point)

		left  := [2]i32{temp_point.data.x + 1, temp_point.data.y}
		down  := [2]i32{temp_point.data.x, temp_point.data.y + 1}
		up    := [2]i32{temp_point.data.x, temp_point.data.y - 1}
		right := [2]i32{temp_point.data.x - 1, temp_point.data.y}

		validate_node(right, temp_point, unvisited, visited)
		validate_node(down, temp_point, unvisited, visited)
		validate_node(up, temp_point, unvisited, visited)
		validate_node(left, temp_point, unvisited, visited)
	}

	goal_index := find_pos(goal, visited)
	path := make_dynamic_array([dynamic][2]i32)
	defer delete(path)
	if goal_index > -1 {
		curr_node := visited[goal_index]
		for curr_node.parent_hndl != -1 {
			append(&path, curr_node.data)
			curr_node = visited[curr_node.parent_hndl]
		}
	}

	count:i32 = 0
	#reverse for m in path {
		if count >= entity.movement {
			break
		}
		kind: Action_Type
		switch game_state.grid[m.y][m.x].e_type {
		case .FREE: kind = .MOVE
		case .ENEMY: kind = .BLANK
		case .WALL: kind = .BLANK
		case .P_CREATURE: kind = .DMG
		}
		r := Resolve{kind, entity.id, m}
		append(&game_state.resolves, r)
		count += 1
	}
	entity.resolve_hndl = i32(len(game_state.resolves))
}

//UTILS
validate_node :: proc(peek_pos: [2]i32, start_node: Node, unvisited, visited: [dynamic]Node) {
	if valid_cell(peek_pos) {
		temp_dist := math.abs((peek_pos.x - start_node.data.x) + (peek_pos.y - start_node.data.y))
		new_dist := start_node.dist + temp_dist
		if !contains(peek_pos, visited) { 
			index := find_pos(peek_pos, unvisited)
			if index > -1 && unvisited[index].dist > start_node.dist + 1 {
				unvisited[index].dist = new_dist
				unvisited[index].parent_hndl = start_node.id
			}
		} else {
			index := find_pos(peek_pos, visited)
			if index > -1 && visited[index].dist > start_node.dist + 1 {
				visited[index].dist = new_dist
				visited[index].parent_hndl = start_node.id
			}
		}
	}
}

contains :: proc(pos: [2]i32, points: [dynamic]Node) -> bool {
	does_contain := false
	for point in points {
		if point.data == pos {
			does_contain = true
			break
		}
	}
	return does_contain
}

resolve_contains :: proc(pos: [2]i32, points: [dynamic]Resolve) -> bool {
	does_contain := false
	for point in points {
		if point.target == pos {
			does_contain = true
			break
		}
	}
	return does_contain
}


find_pos :: proc(goal: [2]i32, nodes: [dynamic]Node) -> i32 {
	for &node, index in nodes {
		if node.data == goal {
			return i32(index)
		}
	}
	return -1
}


valid_cell :: proc(pos: [2]i32) -> bool {
	valid: bool
	valid = (pos.x < len(game_state.grid[0]) && pos.x >= 0) && (pos.y < len(game_state.grid) && pos.y >= 0)
	if valid {
		switch game_state.grid[pos.y][pos.x].e_type {
		case .WALL: valid = false
		case .ENEMY: valid = false
		case .P_CREATURE: valid = true
		case .FREE: valid = true
		}
	}

	return valid
}

find_shortest_dist :: proc(nodes: [dynamic]Node) -> i32 {
	shortest:i32 = i32(99999)
	i:i32 = -1
	for node, index in nodes {
		if node.dist < shortest {
			shortest = node.dist
			i = i32(index)
		}
	}

	return i
}

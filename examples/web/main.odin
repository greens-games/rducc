package main

import "core:fmt"
import "../../plumage/web"

main :: proc() {
	web.init(920, 680, "test-canvas")
	fmt.println("Hello sailor")
}

@(export)
step :: proc(dt: f32) -> (keep_going: bool) {
	web.background_clear(web.GRAY)
	web.box_push({0, 0}, {32, 32}, web.RED)
	web.text_push("Hello Sailer", {0, 0}, 16)
	web.commit()
	return true
}

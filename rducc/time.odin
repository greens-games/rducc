package rducc

import "vendor:glfw"

//NOTE: This might be more precise for timing using core:time
time_delta_get :: proc() -> f64 {
	time := glfw.GetTime()
	delta_time := time - ctx.time
	ctx.time = time
	return delta_time
}

time_get :: proc() -> f64 {
	return glfw.GetTime()
}

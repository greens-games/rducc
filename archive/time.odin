package rducc

import "vendor:glfw"

//NOTE: This might be more precise for timing using core:time
/* This should only be called once in your loop at the start for now otherwise you will get inaccurate values 
   Save it to a variable and use that
*/
time_delta_get :: proc() -> f64 {
	time := glfw.GetTime()
	delta_time := time - ctx.time
	ctx.time = time
	return delta_time
}

time_get :: proc() -> f64 {
	return glfw.GetTime()
}

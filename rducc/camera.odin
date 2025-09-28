package rducc

Camera :: struct {
	target: [2]f32,
	zoom:      f32,
}

camera_init :: proc(zoom: f32) {
	ctx.camera.zoom = zoom
}

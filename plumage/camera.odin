package plumage

import "core:math/linalg"
import gl "vendor:OpenGL"

/**
NOTE: We might want to look into using some other structure for cameras instead of requiring sandwiching calls within certain api calls
*/

Camera_2D :: struct {
	target: [2]f32,
	zoom:      f32,
}

/**
Initialize camera with certain params
return the camera struct for the user to own
*/
camera_init :: proc(target: [2]f32, zoom: f32) -> Camera_2D {
	camera: Camera_2D
	camera.zoom = zoom
	camera.target = target
	return camera
}

/**
REQUIRED to start using a camera for a given chunk of draws
centres camera on 'target', and applies a view translation to all things drawn withing the camera begin and camera end
*/
camera_begin :: proc(camera: Camera_2D) {
	ctx.camera = camera
	c := ctx.camera.(Camera_2D)
	inv_target_translate := linalg.matrix4_translate_f32({-c.target.x, -c.target.y, 0})
	/* inv_rot := linalg.matrix4_rotate_f32(c.rotation, {0, 0, 1}) */
	inv_scale := linalg.matrix4_scale_f32({c.zoom, c.zoom, 1})
	/* inv_offset_translate := linalg.matrix4_translate(vec3_from_vec2(c.offset)) */
	inv_offset_translate := linalg.matrix4_translate_f32({f32(ctx.window_width)/2, f32(ctx.window_height)/2, 0})
	ctx.view_matrix = inv_offset_translate * inv_scale * inv_target_translate
}

/**
REQUIRED to commit draws for a camera
Applies current view matrix
Commits the batch to ensure it's flushed
Resets to identity matrix for default vert shader
*/
camera_end :: proc() {
	gl.UniformMatrix4fv(ctx.loaded_uniforms["view"].location, 1, false, &ctx.view_matrix[0, 0])
	commit()
	ctx.view_matrix = linalg.identity(matrix[4, 4]f32)
	gl.UniformMatrix4fv(ctx.loaded_uniforms["view"].location, 1, false, &ctx.view_matrix[0, 0])
}

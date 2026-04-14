package plumage

/**
NOTE: We might want to look into using some other structure for cameras instead of requiring sandwiching calls within certain api calls
*/

Camera_2D :: struct {
	target: [2]f32,
	zoom:      f32,
}

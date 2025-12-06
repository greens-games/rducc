package temp

blah :: proc() {
	c:rune = 'L'
	v:i32 = 68
	start:i32 = 50
	if c == 'L' {
		res := start - v
		if res < 0 {
			res = 100 - res
		}
	}
}

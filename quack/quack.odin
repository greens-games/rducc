package quack

import "core:mem"
import ma "vendor:miniaudio"

//TODO: This currently is just a wrapper to miniaudio's high-level api
//In the future we want this to be low-level miniaudio api and then
//eventaully our own audio functionality as we learn more about audio data
//Using platform specific APIs and logic
Quack_Sound :: struct {
	data: ma.sound,
	loop: bool,
	decorder: ma.decoder,
}

Quack_Context :: struct {
	engine:     ma.engine,
	sounds:     [dynamic]Quack_Sound,
	curr_sound: ^Quack_Sound,
}

ctx: Quack_Context

audio_init :: proc() {
	ma.engine_init(nil, &ctx.engine)
	ctx.sounds = make_dynamic_array([dynamic]Quack_Sound)
}

sound_load_from_bytes :: proc(data: []u8) {
	//NOTE: try using something in here github.com/mackron/issues/731 the gist has a potential example
	sound: Quack_Sound
	append(&ctx.sounds, sound)
	/* decorder_config := ma.decoder_config_init(.u8, u32(header.num_channels), u32(header.sample_rate)) */
	ma.decoder_init_memory(raw_data(data), len(data), nil, &(ctx.sounds[len(ctx.sounds) - 1].decorder))
	ma.sound_init_from_data_source(
		&ctx.engine,
		cast(^ma.data_source)&ctx.sounds[len(ctx.sounds) - 1].decorder,
		{.STREAM, .DECODE},
		nil,
		&ctx.sounds[len(ctx.sounds) - 1].data
	)
}

sound_load_from_file :: proc(file_path: cstring) {
	sound: Quack_Sound
	append(&ctx.sounds, sound)
	ma.sound_init_from_file(
		&ctx.engine,
		file_path,
		{.STREAM, .DECODE},
		nil,
		nil,
		&ctx.sounds[len(ctx.sounds) - 1].data
	)
}

play_sound :: proc(index: i32, loop: bool = false) {
	sound := &ctx.sounds[index]
	ma.sound_seek_to_pcm_frame(&sound.data, 0)
	ma.sound_start(&sound.data)
	if loop {
		ctx.curr_sound = sound
	}
}

/**
currently just repeats the current looping sound (there can only be one right now)
*/
update_audio :: proc() {
	assert(ctx.curr_sound != nil)
	if ctx.curr_sound.data.atEnd {
		ma.sound_seek_to_pcm_frame(&ctx.curr_sound.data, 0)
		ma.sound_start(&ctx.curr_sound.data)
	}
}

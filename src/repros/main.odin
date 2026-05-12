// See https://github.com/karl-zylinski/karl2d/pull/169
package reproducer

import k2 "../odyn_deps/karl2d"

import "core:fmt"
import "core:math"
import "core:mem"
import "base:runtime"

context_global : runtime.Context
mem_tracker: mem.Tracking_Allocator

main :: proc() {
	init()
	for step() {}
	shutdown()
}

init :: proc() {
	mem.tracking_allocator_init(&mem_tracker, context.allocator)
	context.allocator = mem.tracking_allocator(&mem_tracker)
	context_global = context

	k2.init(1280, 720, "", options = {window_mode = .Windowed_Resizable})
}

step :: proc() -> bool {
	context = context_global

	if !k2.update() {
		return false
	}

	if k2.key_went_down(.Escape) {
		return false
	}

	t := f32(k2.get_time() * 5)
	// Make sure each value never drops below half to prevent an unpleasant "blackout" effect as the colors change.
	red   := u8((math.sin_f32(t + 0.0)   * 0.5 + 0.5) * 255)
	green := u8((math.sin_f32(t + 2.094) * 0.5 + 0.5) * 255)
	blue  := u8((math.sin_f32(t + 4.189) * 0.5 + 0.5) * 255)
	color := k2.Color{red, green, blue, 255}
	k2.clear(color)

	return true
}

shutdown :: proc() {
	context = context_global
	defer {
		if len(mem_tracker.allocation_map) > 0 {
			for _, entry in mem_tracker.allocation_map {
				fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
			}
		}
		mem.tracking_allocator_destroy(&mem_tracker)
	}

	k2.shutdown()
}

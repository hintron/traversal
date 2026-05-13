package traversal

// Third-party dependencies
import k2 "shared:karl2d"
import "shared:tracker" // tracker imports "shared/afmt"
// Note: The "shared:" syntax requires registering odyn_deps as the "shared" collection with -collection:shared=odyn_deps. tracker requires this in order to import afmt.
// Could also do "odyn_deps/karl2d"

import "core:fmt"
import "core:math/linalg"
import "core:math"
import "core:container/xar"
import "core:container/queue"
import "core:strings"
import "core:mem"
import "base:runtime"

// main() is for non-web builds. Web builds will call init(), step(), and
// shutdown() directly, without calling main
main :: proc() {
	init()
	for step() {}
	shutdown()
}

TITLE :: "Traversal"
TITLE_FONT_SIZE :: 100
title_center_offset_x: f32

PLAYER_RADIUS : f32 = 30.0
PLAYER_WIDTH : f32 = 60.0
PLAYER_HEIGHT : f32 = 60.0
PLAYER_OFFSET: k2.Vec2
center_of_screen: k2.Vec2
player_pos: k2.Vec2 // This will be relative to the center of the screen
player_cmd_queue: queue.Queue(PlayerCmd) // Default capacity is 16
player_cmd_history: xar.Array(PlayerCmd, 10) // 2^10 or 1024 initial capacity
last_printed_second: i64

show_debug_info : bool
colorful_background_mode : bool
zoom_level : f32 = 1.0
current_screen_size: k2.Vec2
// The camera's position (target) is the upper-left corner of the window.
// To make that position be the center of the screen, we need to add an offset to target.
world_camera: k2.Camera

// Add a command-line define to trigger mem leaks, to test the tracking allocator
// -define:MEM_LEAKS=true
MEM_LEAKS :: #config(MEM_LEAKS, false)
SHUTDOWN_SECS : f64 : #config(SHUTDOWN_SECS, 0.0)
USE_FANCY_TRACKING_ALLOCATOR :: #config(FANCY_TRACKER, false)

when ODIN_DEBUG && !USE_FANCY_TRACKING_ALLOCATOR {
	context_global : runtime.Context
	mem_tracker: mem.Tracking_Allocator
}

// Ensure that the fancy tracking allocator can only be used in debug mode
#assert(!USE_FANCY_TRACKING_ALLOCATOR || ODIN_DEBUG)

PlayerCmd :: enum {
	MoveLeft,
	MoveRight,
	MoveUp,
	MoveDown,
	MoveUpLeft,
	MoveUpRight,
	MoveDownLeft,
	MoveDownRight,
}

init :: proc() {
	when ODIN_DEBUG {
		// During debug, set the allocator to a memory tracking allocator, and
		// save off to a global variable so we can use it in other functions in
		// WASM, since WASM has no top-level main().
		// If not targeting WASM, just do it all at once in main()
		when USE_FANCY_TRACKING_ALLOCATOR {
			tracker.NOPANIC = true // Override with: -define:nopanic=false
			tracker.init_global()
			context.allocator = tracker.global.allocator
		} else {
			mem.tracking_allocator_init(&mem_tracker, context.allocator)
			context.allocator = mem.tracking_allocator(&mem_tracker)
			context_global = context
		}

		show_debug_info = true // Show debug info by default
	}

	when MEM_LEAKS {
		never_freed := make([]u8, 1024 * 1024) // 1 MB leak to test mem tracker
	}

	fmt.println("Hellope, traversal!")
	k2.init(1280, 720, TITLE, options = {window_mode = .Windowed_Resizable})

	{
		title_text_size := k2.measure_text(TITLE, TITLE_FONT_SIZE)
		title_center_offset_x = title_text_size.x / 2
	}

	// Initialize globals
	PLAYER_OFFSET = {
		PLAYER_WIDTH / 2, PLAYER_HEIGHT / 2
	}
}

step :: proc() -> bool {
	when ODIN_DEBUG { // Must be first!
		when USE_FANCY_TRACKING_ALLOCATOR {
			context.allocator = tracker.global.allocator
		} else {
			context = context_global
		}
	}

	if SHUTDOWN_SECS > 0 && k2.get_time() >= SHUTDOWN_SECS {
		return false
	}

	if !k2.update() {
		return false
	}

	if k2.key_went_down(.Escape) {
		return false
	}

	screen_size_changed_this_frame : bool
	if k2.get_screen_size() != current_screen_size {
		current_screen_size = k2.get_screen_size()
		screen_size_changed_this_frame = true
	}

	if screen_size_changed_this_frame {
		world_camera.offset = current_screen_size / 2
		world_camera.zoom = zoom_level
		k2.set_camera(world_camera)
	}

	if colorful_background_mode {
		t := f32(k2.get_time())
		// Making sure each value never drops below half prevents an unpleasant "blackout" effect as the colors change.
		red   := u8((math.sin_f32(t + 0.0)   * 0.5 + 0.5) * 255)
		green := u8((math.sin_f32(t + 2.094) * 0.5 + 0.5) * 255)
		blue  := u8((math.sin_f32(t + 4.189) * 0.5 + 0.5) * 255)
		color := k2.Color{red, green, blue, 255}
		k2.clear(color)
	} else {
		k2.clear(k2.BLACK)
	}

	if k2.key_went_down(.P) {
		show_debug_info = !show_debug_info
	}
	if k2.key_went_down(.C) {
		colorful_background_mode = !colorful_background_mode
	}


	is_shift_held := k2.key_is_held(.Left_Shift) || k2.key_is_held(.Right_Shift)
	zoom_changed := false
	if
		(is_shift_held && k2.key_went_down(.Minus)) ||
		(!is_shift_held && k2.key_is_held(.Minus))
	{
		if zoom_level >= 1.5 {
			zoom_level -= 0.5
		} else {
			zoom_level -= 0.125
		}
		if zoom_level < 0.125 {
			zoom_level = 0.125
		}
		zoom_changed = true
	} else if
		(is_shift_held && k2.key_went_down(.Equal)) ||
		(!is_shift_held && k2.key_is_held(.Equal))
	{
		if zoom_level >= 1.0 {
			zoom_level += 0.5
		} else {
			zoom_level += 0.125
		}
		if zoom_level > 5.0 {
			zoom_level = 5.0
		}
		zoom_changed = true
	}

	// Update the camera if zoom or screen size changed
	if zoom_changed {
		world_camera.zoom = zoom_level
	}

	// Allow multiple input commands to be queued in a single frame
	is_left_down := k2.key_went_down(.Left) || k2.key_went_down(.A)
	is_right_down := k2.key_went_down(.Right) || k2.key_went_down(.D)
	is_up_down := k2.key_went_down(.Up) || k2.key_went_down(.W)
	is_down_down := k2.key_went_down(.Down) || k2.key_went_down(.S)
	is_left_held := k2.key_is_held(.Left) || k2.key_is_held(.A)
	is_right_held := k2.key_is_held(.Right) || k2.key_is_held(.D)
	is_up_held := k2.key_is_held(.Up) || k2.key_is_held(.W)
	is_down_held := k2.key_is_held(.Down) || k2.key_is_held(.S)

	if
		(is_up_down && is_left_down && is_shift_held) ||
		(is_up_held && is_left_held && !is_shift_held)
	{
		queue.enqueue(&player_cmd_queue, PlayerCmd.MoveUpLeft)
	}
	else if
		(is_up_down && is_right_down && is_shift_held) ||
		(is_up_held && is_right_held && !is_shift_held)
	{
		queue.enqueue(&player_cmd_queue, PlayerCmd.MoveUpRight)
	}
	else if
		(is_down_down && is_left_down && is_shift_held) ||
		(is_down_held && is_left_held && !is_shift_held)
	{
		queue.enqueue(&player_cmd_queue, PlayerCmd.MoveDownLeft)
	}
	else if
		(is_down_down && is_right_down && is_shift_held) ||
		(is_down_held && is_right_held && !is_shift_held)
	{
		queue.enqueue(&player_cmd_queue, PlayerCmd.MoveDownRight)
	}
	else if
		(is_left_down && is_shift_held) ||
		(is_left_held && !is_shift_held)
	{
		queue.enqueue(&player_cmd_queue, PlayerCmd.MoveLeft)
	}
	else if
		(is_right_down && is_shift_held) ||
		(is_right_held && !is_shift_held)
	{
		queue.enqueue(&player_cmd_queue, PlayerCmd.MoveRight)
	}
	else if
		(is_up_down && is_shift_held) ||
		(is_up_held && !is_shift_held)
	{
		queue.enqueue(&player_cmd_queue, PlayerCmd.MoveUp)
	}
	else if
		(is_down_down && is_shift_held) ||
		(is_down_held && !is_shift_held)
	{
		queue.enqueue(&player_cmd_queue, PlayerCmd.MoveDown)
	}

	// Get user input
	// movement_cmd: PlayerCmd
	movement: k2.Vec2

	// Move player according to input command queue, once per frame
	// TODO: Use delta time to know when to allow a move command to occur
	// TODO: Animate player movement and don't allow new move commands during animation (but still allow movement queuing)
	if movement_cmd, exists := queue.pop_front_safe(&player_cmd_queue); exists {
		xar.push_back(&player_cmd_history, movement_cmd)

		// Calculate the movement vector based on the command
		switch movement_cmd {
			case .MoveLeft:
				movement.x -= 10
			case .MoveRight:
				movement.x += 10
			case .MoveUp:
				movement.y -= 10
			case .MoveDown:
				movement.y += 10
			case .MoveUpLeft:
				movement.x -= 10
				movement.y -= 10
			case .MoveUpRight:
				movement.x += 10
				movement.y -= 10
			case .MoveDownLeft:
				movement.x -= 10
				movement.y += 10
			case .MoveDownRight:
				movement.x += 10
				movement.y += 10
		}
	}

	width := k2.get_screen_width()
	height := k2.get_screen_height()
	center_of_screen = current_screen_size / 2
	// Normalizing makes the movement not go faster when going diagonally.
	player_pos += linalg.normalize0(movement) * k2.get_frame_time() * 400

	frame_draw_time := k2.get_frame_time()
	fps := 1.0 / frame_draw_time

	if SHUTDOWN_SECS > 0 {
		seconds_remaining := i64(SHUTDOWN_SECS - k2.get_time()) + 1
		if seconds_remaining >= 0 {
			// Draw shutdown timer
			shutdown_str := strings.builder_make(context.temp_allocator)
			strings.write_string(&shutdown_str, "Shutting down in ")
			strings.write_i64(&shutdown_str, seconds_remaining)
			strings.write_string(&shutdown_str, " second")
			if seconds_remaining != 1 {
				strings.write_string(&shutdown_str, "s")
			}
			str := strings.to_string(shutdown_str)
			shutdown_str_center_offset_x := k2.measure_text(TITLE, TITLE_FONT_SIZE).x / 2
			k2.draw_text(
				str,
				{
					f32(width) / 2 - shutdown_str_center_offset_x,
					f32(height) / 2
				},
				30,
				k2.RED
			)

			if seconds_remaining != last_printed_second {
				if last_printed_second != 0 {
					fmt.println(str)
				}
				last_printed_second = seconds_remaining
			}
		}
	}

	// Draw title in center of screen
	k2.draw_text(TITLE, {f32(width) / 2 - title_center_offset_x, 20}, TITLE_FONT_SIZE, k2.DARK_BLUE)

	// Draw background grid
	{
		grid_step : f32 = 50.0
		grid_steps_x := f32(width) / grid_step
		grid_steps_y := f32(height) / grid_step
		parallax_enabled := true
		// Draw vertical lines
		for step in -grid_steps_x..<grid_steps_x {
			x := step * grid_step
			if parallax_enabled {
				x -= player_pos.x * 0.5
			}
			k2.draw_line({x, -f32(height)}, {x, f32(height)}, 1.0, k2.DARK_GRAY)
		}
		// Draw horizontal lines
		for step in -grid_steps_y..<grid_steps_y {
			y := step * grid_step
			if parallax_enabled {
				y -= player_pos.y * 0.5
			}
			k2.draw_line({-f32(width), y}, {f32(width), y}, 1.0, k2.DARK_GRAY)
		}
		// Draw cool web-looking happy little accident while trying to draw horizontal lines
		for step in 0..<grid_steps_y {
			y := step * grid_step
			k2.draw_line({0, y}, {y, f32(height)}, 1.0, k2.DARK_GRAY)
		}
	}

	// Debug info block
	if show_debug_info {
		// Draw player info
		player_str := strings.builder_make(context.temp_allocator)
		strings.write_string(&player_str, "Player: (x: ")
		strings.write_f32(&player_str, player_pos.x, 'f')
		strings.write_string(&player_str, ", y: ")
		strings.write_f32(&player_str, player_pos.y, 'f')
		strings.write_string(&player_str, ")")
		k2.draw_text(strings.to_string(player_str), {50, 100}, 30, k2.DARK_BLUE)

		// Draw FPS
		fps_str := strings.builder_make(context.temp_allocator)
		strings.write_string(&fps_str, "FPS: ")
		strings.write_f32(&fps_str, fps, 'f')
		strings.write_string(&fps_str, " (")
		strings.write_f32(&fps_str, frame_draw_time * 1000, 'f')
		strings.write_string(&fps_str, " ms)")
		k2.draw_text(strings.to_string(fps_str), {50, 150}, 30, k2.DARK_BLUE)

		// Draw Screen Dimensions and camera zoom
		debug_str := strings.builder_make(context.temp_allocator)
		strings.write_string(&debug_str, "Screen: (x: ")
		strings.write_int(&debug_str, width)
		strings.write_string(&debug_str, ", y: ")
		strings.write_int(&debug_str, height)
		strings.write_string(&debug_str, ", zoom: ")
		strings.write_f32(&debug_str, zoom_level, 'f')
		strings.write_string(&debug_str, ")")
		k2.draw_text(strings.to_string(debug_str), {50, 200}, 30, k2.DARK_BLUE)

		// Draw command history
		command_history_y_offset : f32 = 250.0
		k2.draw_text("Command History:", {50, command_history_y_offset}, 20, k2.DARK_BLUE)
		count := 0
		draw_offset: f32 = 0.0
		len := xar.len(player_cmd_history)
		command_history_iter := xar.iterator(&player_cmd_history)
		for cmd in xar.iterate_by_val(&command_history_iter) {
			count += 1

			// Show only the last 5 commands
			if len > 5 && count <= len - 5 {
				continue
			}

			draw_offset += 25.0
			strings.write_string(&fps_str, "* ")
			switch cmd {
				case .MoveLeft:
					k2.draw_text("* MoveLeft", {50, command_history_y_offset + draw_offset}, 20, k2.DARK_BLUE)
				case .MoveRight:
					k2.draw_text("* MoveRight", {50, command_history_y_offset + draw_offset}, 20, k2.DARK_BLUE)
				case .MoveUp:
					k2.draw_text("* MoveUp", {50, command_history_y_offset + draw_offset}, 20, k2.DARK_BLUE)
				case .MoveDown:
					k2.draw_text("* MoveDown", {50, command_history_y_offset + draw_offset}, 20, k2.DARK_BLUE)
				case .MoveUpLeft:
					k2.draw_text("* MoveUpLeft", {50, command_history_y_offset + draw_offset}, 20, k2.DARK_BLUE)
				case .MoveUpRight:
					k2.draw_text("* MoveUpRight", {50, command_history_y_offset + draw_offset}, 20, k2.DARK_BLUE)
				case .MoveDownLeft:
					k2.draw_text("* MoveDownLeft", {50, command_history_y_offset + draw_offset}, 20, k2.DARK_BLUE)
				case .MoveDownRight:
					k2.draw_text("* MoveDownRight", {50, command_history_y_offset + draw_offset}, 20, k2.DARK_BLUE)
			}
		}
	} else {
		k2.draw_text("Press P to show debug info", {10, f32(height) - 40.0}, 30, k2.DARK_BLUE)
	}

	// Draw player
	k2.draw_circle(player_pos, PLAYER_RADIUS, k2.DARK_BLUE)
	k2.draw_circle(player_pos, PLAYER_RADIUS - 10.0, k2.BLUE)

	// Draw obstacles
	k2.draw_rect({10, 10, 60, 60}, k2.GREEN)
	k2.draw_rect({20, 20, 40, 40}, k2.LIGHT_GREEN)

	k2.present()

	free_all(context.temp_allocator)
	return true
}

shutdown :: proc() {
	when ODIN_DEBUG { // Must be first!
		when USE_FANCY_TRACKING_ALLOCATOR {
			context.allocator = tracker.global.allocator
			defer tracker.print_and_destroy(&tracker.global)
		} else {
			context = context_global
			defer {
				if len(mem_tracker.allocation_map) > 0 {
					for _, entry in mem_tracker.allocation_map {
						fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
					}
				}
				mem.tracking_allocator_destroy(&mem_tracker)
			}
		}
	}

	fmt.println("Shutting down traversal", flush = true)

	when MEM_LEAKS {
		never_freed := make([]u8, 1024 * 1024) // 1 MB leak to test mem tracker
	}

	xar.destroy(&player_cmd_history)
	queue.destroy(&player_cmd_queue)
	k2.shutdown()
}

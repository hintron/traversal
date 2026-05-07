package traversal

import k2 "odyn_deps/karl2d"
import "core:fmt"
import "core:math/linalg"
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


PLAYER_RADIUS : f32 = 30.0
PLAYER_WIDTH : f32 = 60.0
PLAYER_HEIGHT : f32 = 60.0
PLAYER_OFFSET: k2.Vec2
center_of_screen: k2.Vec2
player_pos: k2.Vec2 // This will be relative to the center of the screen
player_cmd_queue: queue.Queue(PlayerCmd) // Default capacity is 16
player_cmd_history: xar.Array(PlayerCmd, 10) // 2^10 or 1024 initial capacity
last_printed_second: i64
// Add a command-line define to trigger mem leaks, to test the tracking allocator
// -define:MEM_LEAKS=true
MEM_LEAKS :: #config(MEM_LEAKS, false)
SHUTDOWN_SECS : f64 : #config(SHUTDOWN_SECS, 0.0)

when ODIN_DEBUG {
	context_global : runtime.Context
	mem_tracker: mem.Tracking_Allocator
}

PlayerCmd :: enum {
	MoveLeft,
	MoveRight,
	MoveUp,
	MoveDown,
}

init :: proc() {
	when ODIN_DEBUG {
		// During debug, set the allocator to a memory tracking allocator, and
		// save off to a global variable so we can use it in other functions in
		// WASM, since WASM has no top-level main().
		// If not targeting WASM, just do it all at once in main()
		mem.tracking_allocator_init(&mem_tracker, context.allocator)
		context.allocator = mem.tracking_allocator(&mem_tracker)
		context_global = context
	}

	when MEM_LEAKS {
		never_freed := make([]u8, 1024 * 1024) // 1 MB leak to test mem tracker
	}

	fmt.println("Hellope, traversal!")
	k2.init(1280, 720, "Traversal", options = {window_mode = .Windowed_Resizable})

	// Initialize globals
	PLAYER_OFFSET = {
		PLAYER_WIDTH / 2, PLAYER_HEIGHT / 2
	}

	center_of_screen = k2.get_screen_size() / 2
}

step :: proc() -> bool {
	when ODIN_DEBUG { // Must be first!
		context = context_global
	}

	if SHUTDOWN_SECS > 0 && k2.get_time() >= SHUTDOWN_SECS {
		return false
	}

	if !k2.update() {
		return false
	}

	// Allow multiple input commands to be queued in a single frame
	is_shift_held := k2.key_is_held(.Left_Shift) || k2.key_is_held(.Right_Shift)
	if
		(
			(k2.key_went_down(.Left) || k2.key_went_down(.A)) &&
			(is_shift_held)
		) ||
		(
			(k2.key_is_held(.Left) || k2.key_is_held(.A)) &&
			(!is_shift_held)
		)
	{
		queue.enqueue(&player_cmd_queue, PlayerCmd.MoveLeft)
	}

	if
		(
			(k2.key_went_down(.Right) || k2.key_went_down(.D)) &&
			(is_shift_held)
		) ||
		(
			(k2.key_is_held(.Right) || k2.key_is_held(.D)) &&
			(!is_shift_held)
		)
	{
		queue.enqueue(&player_cmd_queue, PlayerCmd.MoveRight)
	}

	if
		(
			(k2.key_went_down(.Up) || k2.key_went_down(.W)) &&
			(is_shift_held)
		) ||
		(
			(k2.key_is_held(.Up) || k2.key_is_held(.W)) &&
			(!is_shift_held)
		)
	{
		queue.enqueue(&player_cmd_queue, PlayerCmd.MoveUp)
	}

	if
		(
			(k2.key_went_down(.Down) || k2.key_went_down(.S)) &&
			(is_shift_held)
		) ||
		(
			(k2.key_is_held(.Down) || k2.key_is_held(.S)) &&
			(!is_shift_held)
		)
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
		}
	}

	center_of_screen = k2.get_screen_size() / 2
	// Normalizing makes the movement not go faster when going diagonally.
	player_pos += linalg.normalize0(movement) * k2.get_frame_time() * 400

	frame_draw_time := k2.get_frame_time()
	fps := 1.0 / frame_draw_time
	fps_str := strings.builder_make(context.temp_allocator)
	strings.write_string(&fps_str, "FPS: ")
	strings.write_f32(&fps_str, fps, 'f')
	strings.write_string(&fps_str, " (")
	strings.write_f32(&fps_str, frame_draw_time * 1000, 'f')
	strings.write_string(&fps_str, " ms)")
	if SHUTDOWN_SECS > 0 {
		seconds_remaining := i64(SHUTDOWN_SECS - k2.get_time()) + 1
		if seconds_remaining >= 0 {
			strings.write_string(&fps_str, " - Shutting down in ")
			strings.write_i64(&fps_str, seconds_remaining)
			strings.write_string(&fps_str, " second")
			if seconds_remaining != 1 {
				strings.write_string(&fps_str, "s")
			}
			if seconds_remaining != last_printed_second {
				if last_printed_second != 0 {
					fmt.println("Shutting down in ", seconds_remaining, " seconds")
				}
				last_printed_second = seconds_remaining
			}
		}
	}
	debug_str := strings.builder_make(context.temp_allocator)
	strings.write_string(&debug_str, "Screen: (x: ")
	strings.write_int(&debug_str, k2.get_screen_width())
	strings.write_string(&debug_str, ", y: ")
	strings.write_int(&debug_str, k2.get_screen_height())
	strings.write_string(&debug_str, ") ")
	strings.write_string(&debug_str, fmt.tprintfln(" (%v)", k2.get_screen_size()))

	k2.clear(k2.BLACK)

	// Draw title
	k2.draw_text("Traversal", {50, 50}, 100, k2.DARK_BLUE)

	// Draw FPS
	k2.draw_text(strings.to_string(fps_str), {50, 150}, 30, k2.DARK_BLUE)

	// Draw Screen Dimensions
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
		}
	}

	// Draw player
	k2.draw_circle(center_of_screen + player_pos + PLAYER_OFFSET, PLAYER_RADIUS, k2.DARK_BLUE)
	k2.draw_circle(center_of_screen + player_pos + PLAYER_OFFSET, PLAYER_RADIUS - 10.0, k2.BLUE)

	// Draw obstacles
	k2.draw_rect({10, 10, 60, 60}, k2.GREEN)
	k2.draw_rect({20, 20, 40, 40}, k2.LIGHT_GREEN)

	k2.present()

	free_all(context.temp_allocator)
	return true
}

shutdown :: proc() {
	when ODIN_DEBUG { // Must be first!
		context = context_global
	}

	// MGH TODO: This doesn't print out in WASM! Why doesn't WASM hit shutdown?
	fmt.println("Shutting down traversal", flush = true)

	when MEM_LEAKS {
		never_freed := make([]u8, 1024 * 1024) // 1 MB leak to test mem tracker
	}

	xar.destroy(&player_cmd_history)
	queue.destroy(&player_cmd_queue)
	k2.shutdown()

	when ODIN_DEBUG {
		if len(mem_tracker.allocation_map) > 0 {
			for _, entry in mem_tracker.allocation_map {
				fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
			}
		}
		mem.tracking_allocator_destroy(&mem_tracker)
	}
}

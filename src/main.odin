package traversal

import k2 "odyn_deps/karl2d"
import "core:fmt"
import "core:math/linalg"

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
player_pos: k2.Vec2

init :: proc() {
    fmt.println("Hellope, traversal!")
    k2.init(1280, 720, "Greetings from Karl2D!", options = {window_mode = .Windowed_Resizable})

    PLAYER_OFFSET = {
        PLAYER_WIDTH / 2, PLAYER_HEIGHT / 2
    }
    player_pos = k2.Vec2 {
        0, 0
    }
}



step :: proc() -> bool {
    if !k2.update() {
        return false
    }

    // Get user input
	movement: k2.Vec2
	if k2.key_is_held(.Left) {
		movement.x -= 1
	}
	if k2.key_is_held(.Right) {
		movement.x += 1
	}
	if k2.key_is_held(.Up) {
		movement.y -= 1
	}
	if k2.key_is_held(.Down) {
		movement.y += 1
	}

	// Normalizing makes the movement not go faster when going diagonally.
	player_pos += linalg.normalize0(movement) * k2.get_frame_time() * 400

    k2.clear(k2.BLACK)
    k2.draw_text("Hellope!", {50, 50}, 100, k2.DARK_BLUE)

	k2.draw_circle(player_pos + PLAYER_OFFSET, PLAYER_RADIUS, k2.DARK_BLUE)
	k2.draw_circle(player_pos + PLAYER_OFFSET, PLAYER_RADIUS - 10.0, k2.BLUE)

    k2.present()

    return true
}

shutdown :: proc() {
    k2.shutdown()
}
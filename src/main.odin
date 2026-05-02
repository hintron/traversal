package traversal

import k2 "odyn_deps/karl2d"
import "core:fmt"

// main() is for non-web builds. Web builds will call init(), step(), and
// shutdown() directly, without calling main
main :: proc() {
    init()
    for step() {}
    shutdown()
}

init :: proc() {
    fmt.println("Hellope, traversal!")
    k2.init(1280, 720, "Greetings from Karl2D!")
}

step :: proc() -> bool {
    if !k2.update() {
        return false
    }

    k2.clear(k2.LIGHT_BLUE)
    k2.draw_text("Hellope!", {50, 50}, 100, k2.DARK_BLUE)
    k2.present()

    return true
}

shutdown :: proc() {
    k2.shutdown()
}
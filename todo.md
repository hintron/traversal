# TODO Items

## On Deck

* Create basic collision detection with an object.

* Create jump nodes of two things connected by a line, where the first node stores the location or a pointer to the second node (or do Anton's intrusive lists?)

* When colliding with one end of a jump node, move the player to the other end.

* Consume the node and add juice.

* Auto generate multiple nodes

* Have the camera follow the player's movement.

* Create a simple set of path segments that the player moves across.

* Get the player's movement to snap to path segments.

* Generate 3 random obstacles.

* Allow random seed to be specified.

* Create data structure to record entire generated obstacle tree.

* Animate the player to move to one of three obstacles when selected.

* Make camera follow player (with lag and easing?).

* Record the player's choice.

* Generate 3 more random obstacles.

* When the player hits an obstacle of death, end the game.

* Show the current score (number of cleared levels + speed bonus) in the top left.

* Add a rising lava tide.

* When the rising lava tide reaches the bottom of the player's circle, end the game.

* Add a blocker obstacle, where selecting freezes the player's input for a short time.

* Make the rising lava tide get faster as the player's score gets higher.

* Add a player idle animation.


## Near-Term Tasks

* Get left, right, and up mobile input buttons working.

* Show the equation used to generate score, so players know what to game for.

* Implement a camera shake effect on a button press


## Completed

* Add ability to zoom the camera in and out, for debug.

* Get a camera set up, and make sure player movement and grid still work.

* Show debug info with a button press

* Get player in center of screen.

* Show last 5 commands in command history.

* Show FPS using get_frame_time().

* Get left, right, and up keyboard input working.


## Ideas

* Make the camera smoothly follow the player, with an ease in/ease out motion (or with a box trigger, where X pixels from the edge triggers a camera move)

* Set 60 or 120 or 144 FPS as the frame rate target.

* Add profiling instrumentation to know how long different parts of the code take per frame.

* Make death obstacles look like hot lava.

* At end of game, show full score calculation.

* Add a mini-map or a distance indicator to indicate how close the lava is.

* When the game ends, do a replay of the commands (replay at double speed?).

* When game ends, show path player took along with score calculations.

* Make death obstacles look like hot lava.

* Shader to make lava look cool.

* Shader to make player moving look fast and blurry.

* Add whooshing sound when player moves.

* Add some kind of increasing sound to indicate how close the lava is to the player.

* Add a visual indicator to show how close the lava is.

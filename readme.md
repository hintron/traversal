# Traversal: [Karl2d Game Jam](https://itch.io/jam/karl2d-jam) Submission

https://hintron.itch.io/karl2d-game-jam-submission-traversal

UPDATE (2026-5-3): Don't vote for this!

Unfortunately, due to family commitments, I did not have enough free time over the weekend to get a playable game. But I was able to get the foundation started for my first Karl2d project, and I got more familiar with Odin as one of my first Odin projects. I also made sure not to use AI (though AI doesn't really know about Odin anyways), which has been fun and refreshing.

I did get a player avatar moving on the screen, got user input parsed into commands, and got the commands saved to history and displayed, and got a web build working. I also mapped out my TODO list into doable steps moving forward. I probably spent 6-8 hours in total up to this point.

In the upcoming week, I plan to finish what I started and post the result to GitHub pages here in this repo. I want to give the project a full 24 hours and see what I can accomplish in that time.


# Build Instructions

Clone this repo:
```
git clone https://github.com/hintron/traversal.git
cd traversal/src
```

Then, use the [Odyn reproducable vendoring tool](https://codeberg.org/razkar/odyn) to automatically download Karl2d (and potentially other third-party dependencies):
```
odyn sync
```

Finally, build and run with the [Odin](https://odin-lang.org/docs/install/) compiler:
```
odin run .
```

When using a local Git-cloned Odin, I had to do

```
make -C "<path_to_odin>/vendor/stb/src"
```

## Web Build

```
cd src
odin run odyn_deps/karl2d/build_web -- . -o:size
cd bin/web
python -m http.server
```

Then, open `http://localhost:8000/` in a browser.

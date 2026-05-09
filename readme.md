# Traversal

Traversal is a twitchy climbing game written in [Odin](https://odin-lang.org).

> [!WARNING]
> Currently under development!

This game was initially started as a [Karl2d Game Jam](https://itch.io/jam/karl2d-jam) submission (see https://hintron.itch.io/karl2d-game-jam-submission-traversal).


# Build Instructions

Make sure [Odin is installed](https://odin-lang.org/docs/install/).

Clone this repo:
```
git clone https://github.com/hintron/traversal.git
cd traversal/src
```

Then, download the [Odyn reproducable vendoring tool](https://codeberg.org/razkar/odyn) and use it to automatically download Karl2d and other third-party dependencies required by Traversal:
```
odyn sync
```

Finally, build and run the game:
```
../build.sh --run
```

> [!NOTE]
> When using a local Git-cloned Odin, I had to build `stb`:
>```
>make -C "<path_to_odin>/vendor/stb/src"
>```

To build for both native and web, do:
```
../build.sh
```

> [!TIP]
> Check out [build.sh](./build.sh) for build options.



Or invoke the Odin compiler directly:
```
odin run . -collection:shared=odyn_deps
```

> [!NOTE]
> The `-collection` arg is required to get the `tracker` package to properly import the `afmt` package from `odyn_deps/` (for now).


To manually do a web build and start up an http server, do:

```
cd src
odin run odyn_deps/karl2d/build_web -- . -collection:shared=odyn_deps -o:size
cd bin/web
python -m http.server
```

Then, open `http://localhost:8000/` in a browser to run the game.

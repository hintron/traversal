# Traversal: [Karl2d Game Jam](https://itch.io/jam/karl2d-jam) Submission


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

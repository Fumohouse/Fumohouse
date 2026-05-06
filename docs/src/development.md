# Getting Started

Fumohouse is built using [Godot](https://godotengine.org/). Refer to
[`README.md`](https://git.seki.pw/Fumohouse/Fumohouse/src/branch/main/README.md)
for the currently supported version of Godot (usually the latest stable
version).

To download the Fumohouse source code, use [Git](https://git-scm.com/), then
download all submodules:

```sh
git clone https://git.seki.pw/Fumohouse/Fumohouse
cd Fumohouse
git submodule update --init --recursive
```

Download Godot and open the Fumohouse project. Press F5 to run the main game.

## Development environment

The following additional packages are recommended or required for development.

Formatting:

- [`godot-gdscript-toolkit`](https://github.com/Scony/godot-gdscript-toolkit)
- `svgo`

Documentation:

- `mdbook`

Python scripts:

- Python 3.12+
- Ordered dithering script: `pillow` and `numpy`
- Emoji database script: `polib`

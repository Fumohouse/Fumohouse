# Development environment

## Tools

Fumohouse is built using [Godot](https://godotengine.org/). Refer to
[`README.md`](https://git.seki.pw/Fumohouse/Fumohouse/src/branch/main/README.md)
for the currently supported version of Godot (usually the latest stable
version). Download this version of Godot (non-.NET version) to get started.
Godot is provided as a standalone executable and does not need installing.
However, you may want to add Godot to your `PATH` as `godot4` (view your
operating system documentation for how to do so).

Fumohouse version control is through [Git](https://git-scm.com/). For
contributing, use Git to clone Fumohouse's source code rather than downloading
the source as ZIP/tarball.

The following additional packages are recommended for development.

Formatting:

- [`godot-gdscript-toolkit`](https://github.com/Scony/godot-gdscript-toolkit) for GDScript
- `svgo` for SVG files

Documentation:

- `mdbook`

Python scripts:

- Python 3.12+
- Packages (to be installed with `pip install`):
  - Ordered dithering script: `pillow` and `numpy`
  - Emoji database script: `polib`

## Setup

To download the Fumohouse source code, use Git to clone the repository, then
download all submodules:

```sh
git clone https://git.seki.pw/Fumohouse/Fumohouse
cd Fumohouse
git submodule update --init --recursive
```

Use Godot to open the Fumohouse project. Press F5 to run the main game.

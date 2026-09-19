# Guidelines for Code

Make sure you have read the [common guidelines](./index.md) first.

Code submissions mostly follow industry norms. Specific guidelines are given
below.

## License

Fumohouse requires code submissions to use the [Mozilla Public License version
2.0](https://www.mozilla.org/en-US/MPL/2.0/) (MPL-2.0). By submitting a pull
request, you agree to use this license and represent that you are authorized to
license your submission under it.

## Conventions

1. Follow Godot's [GDScript style
   guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).
1. Catch-all capitalization rules:
   | Casing       | For...                                 |
   |--------------|----------------------------------------|
   | `snake_case` | files,[^filenames] folders, animations |
   | `PascalCase` | classes, autoloads, nodes              |
1. Public interfaces should be documented.
1. Documentation comments should be as close to 80 columns wide as possible
   without going over unless necessary. The Godot editor provides inbuilt 80 and
   100 column guide lines.
1. Do not use Godot's binary resource formats `.res` or `.scn` unless necessary.
1. Use [`gdformat`](https://github.com/Scony/godot-gdscript-toolkit) to format
   GDScript code. For simplicity, always keep the formatter result even if it
   looks bad.

[^filenames]:
    Exceptions: For fonts, use the original name from the author.

## Continue...

- [If you are also submitting assets](./assets-guidelines.md)

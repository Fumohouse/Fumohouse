# Contribution guidelines

Thank you for your interest in contributing to Fumohouse!

1. Contributions are welcome to all Fumohouse projects.
1. Please discuss your plan with maintainers before starting work.
1. Contributions must be provided under the licenses described in
   [Licensing](#licensing) unless otherwise stated.
1. Contributions must not violate others' intellectual property (see
   [Licensing](#licensing)).
1. Contributions must comply with [Credit](#credit) requirements.
1. The use of generative AI in any contribution is prohibited.
1. Contributors should expect feedback from maintainers indicating a) the
   changes that would be required for the contribution to be accepted or b) that
   their contribution will not be accepted. It is up to the maintainers'
   discretion as to whether to accept a contribution.

## Licensing

1. Fumohouse's code is licensed under the [MIT
   license](https://spdx.org/licenses/MIT.html).
1. Fumohouse's original assets are licensed under the [CC BY-SA 4.0
   license](https://creativecommons.org/licenses/by-sa/4.0/deed.en).
   1. Attribution guidelines: Provide the name of the asset's original creator
      (provided in `COPYRIGHT.txt`) or consult with a maintainer.
1. All external intellectual property used by Fumohouse should be used within
   the guidelines provided by its creator.

## Credit

1. All sufficiently large contributions to Fumohouse will be documented and
   credited ingame where appropriate.
1. All credited contributions will remain credited for as long as they are in
   the game except by request.
1. All external intellectual property, even those in the public domain, should
   be credited.

## Conventions

1. Follow Godot's [GDScript style
   guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).
1. Catch-all capitalization rules:
   | Casing       | For...                                         |
   |--------------|------------------------------------------------|
   | `snake_case` | files,[^filenames] folders, animations         |
   | `PascalCase` | classes, autoloads, nodes (incl. in 3D models) |
1. Public interfaces should be documented.
1. Do not use Godot's binary resource formats `.res` or `.scn` unless necessary.

### Formatting and optimization

1. GDScript: Use `gdformat`. For simplicity, always keep the formatter result
   even if it looks bad.
1. SVG: Use `svgo --multipass`.

### 3D modeling

1. Fumohouse uses `.glb` as the main export format for Blender. Use other
   formats only as necessary.
1. For duplicated meshes, try to avoid duplicate mesh data and facilitate mesh
   reuse by exporting the duplciated mesh only once and creating its instances
   in Godot.

[^filenames]:
    Exceptions: For fonts, use the original name from the author.

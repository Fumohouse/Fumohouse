# `@fumohouse/base`: Module system

1. [x] All of Fumohouse's/Fumofas' game code/tooling/assets is organized into
   modules.
1. [x] The module system is based on Godot's addon/plugin system. Each module is
   a Godot plugin and therefore must contain a `plugin.cfg`. By convention, a
   module's plugin script should be named `plugin.gd`.
1. [x] Modules should be named like `res://addons/@<scope>/<module_name>`.
1. [x] Module scopes are typically dedicated to a person or group.
   1. The `@fumohouse` scope is reserved for official Fumohouse modules.
   1. The `@assets` scope should be used for asset collections.
1. [x] Modules must declare dependencies on other modules, if any. Cyclic
   dependency between modules is forbidden.
1. [x] Modules must not depend on any files external to themselves and their
   dependencies.
1. [x] The order in which modules are loaded is determined by a topological
   ordering of the dependency graph.
1. [x] Each module must contain a module manifest `module.tres` next to its
   `plugin.cfg`. The manifest stores dependencies, entry point scene, autoloads,
   restricted API usage, etc.
1. [ ] Each module may contain a Debian-format `COPYRIGHT.txt` next to its
   `plugin.cfg` to declare copyright information. Core modules use the
   `COPYRIGHT.txt` at the root of the Fumohouse repository.
1. [x] Autoload classes/scenes are registered per-module and managed by one
   Godot autoload that loads all module autoloads and and exposes them similar
   to Roblox's `game:GetService()`.[^autoload]
   1. For type safety, module autoloads should have a global class name and
      return their instance through a `get_singleton` static function.
   1. Autoloads are not available earlier than `_ready`.

## Module layout

Where convenient, modules should be arranged by the following convention (in
addition to special files mentioned elsewhere):

1. A module may contain various components denoted by directories. The root of
   the module itself may be a component, an `assets` directory, *or* a
   `resources` directory.
1. A component may contain:
   - Other components
   - Scripts and scenes
   - An `assets` directory
   - A `resources` directory
1. An `assets` directory should contain subdirectories called `textures`,
   `models`, `audio`, `fonts`, and others as necessary. These subdirectories may
   have any organized structure.
1. A `resources` directory should primarily contain `.tres` files and can
   otherwise have any organized structure.

## Security

1. **Modules are not robustly sandboxed or restricted from running dangerous
   code.**
1. Officially distributed modules must be managed or have their source code
   audited regularly by a trusted community member. Static analysis tools may
   assist the review process.
1. It is up to the player to trust the author of each module before using it.
   **Under no circumstance** is Fumohouse responsible for damages caused by
   third-party modules.
1. Distributing malicious code is strictly forbidden.

## Tooling

1. [ ] The module system should include tools for creating, packaging, and
   inspecting modules.
1. [ ] Creating: Provide the basic structure of a new module.[^mkplugin]
1. [ ] Packaging: Save all unsaved changes, copy the project directory to a
   temporary folder, and export all modules individually as PCKs by overriding
   `export_presets.cfg`. Then, all PCKs should have outside files be trimmed
   then be inspected.
1. [ ] Inspecting: Given a packaged module, scan for any defects:
   - Dependencies that are not declared, or cyclic dependencies
   - [FUTURE] Potentially unsafe code: code that follows restricted patterns or
     is suspiciously complex (see
     [here](https://github.com/Scony/godot-gdscript-toolkit) and
     [here](https://semgrep.dev/))

## Module distribution

1. [x] Fumohouse shall distribute official, commonly used modules alongside the
   game itself.
1. [ ] Non-bundled modules shall be hosted in Fumohouse's own Godot AssetLib
   repository.[^assetlib]

[^autoload]:
    Godot's autoload system is unsuitable because autoloads need to change at
    runtime.

[^mkplugin]:
    Godot's plugin dialog has some undesirable behaviors for the module system.

[^assetlib]:
    Custom repositories can be added to Godot through the
    `asset_library/available_urls` option.

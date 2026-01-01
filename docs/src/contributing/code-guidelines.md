# Guidelines for Code

Make sure you have read the [common guidelines](./common-guidelines.md) first.

Code submissions mostly follow industry norms. Specific guidelines are given
below.

## License

Fumohouse requires code submissions to use the [Mozilla Public License version
2.0](https://www.mozilla.org/en-US/MPL/2.0/) (MPL-2.0). By submitting a pull
request, you agree to use this license and represent that you are authorized to
license your submission under it.

## Your copyright

You retain the copyright over your work. Fumohouse does not claim copyright over
your work; it only uses it under the provided license.

## Copyright declaration

If you use any outside work in your submission (e.g., code from StackOverflow),
including those in the public domain, you must declare it in a comment. You must
not infringe others' copyright in your submission.

## Credit

For sufficiently large contributions, we will credit you as long as it is in the
game. Small contributions such as typo fixes will not be credited. You may
submit your work under a pen name, which will also be used for crediting and
copyright purposes.

## Retraction

We accept retraction requests only due to critical issues. For these cases,
submit a pull request reverting your original work.

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

## Process overview

1. Get your contribution [signed off](./common-guidelines.md#sign-off).
1. Fork the relevant repository and create a feature branch for your submission.
1. Create your contribution. If you need help or have any questions, feel free
   to reach out to us.
1. Submit a pull request on [Forgejo](https://git.seki.pw/Fumohouse) or
   [GitHub](https://github.com/Fumohouse) (if available). If your pull request
   is still a work in progress, submit it as a draft. Drafts will not be
   reviewed unless you request a review from a maintainer or mark it ready for
   review.
1. Expect timely feedback on your submission. After you address all comments in
   a review, request a new review when you are ready.
1. Decision: If your submission is approved, expect to be merged in a timely
   manner. You may be asked to rebase and squash your commits.

   If your submission will be rejected, we will let you know as soon as
   possible. Depending on the reason for rejection, you may be able to use part
   of your submission in a future one.

Feel free to reach out to us in the event of any unexpected delays.

## Continue...

- [If you are also submitting assets](./assets-guidelines.md)

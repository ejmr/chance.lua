Chance - Library For Generating Random Data
===========================================

Chance is a [Lua][] port of [Chance.js][], a library for generating
random data for a variety of situations.  However, it is not a perfect
port as it does not support the entire API of the original and not all
functions behave the same way, e.g. the Lua function `chance.float()`
returns numbers in a different range than the original library’s
`chance.floating()`.


Usage
-----

Simply place `chance.lua` somewhere in the package path where
`require()` can find it, and then use the library like so:

```lua
local chance = require("chance")
```

Running [LDoc][] on `chance.lua` will create a `doc/` directory with
detailed information on the library’s API.

If [Tup][] is available then running `tup` within the project
directory will…

1. Run LDoc to create documentation.
2. Test for any errors in the code via [Luacheck][].
3. Run the test suite in `chance.spec.lua` via [Busted][].  Output
   will go into the file `/tmp/chance-busted.log`.
4. Create a `TAGS` file for [Emacs][] via [Exuberant Ctags][ctags].

Tup and all other tools mentioned above are *optional* and not
required to use the Chance library.


License
-------

Copyright 2015 Plutono Inc.

[GNU General Public License 3](./LICENSE)


Miscellaneous
-------------

This project follows [Semantic Versioning](http://semver.org/).



[Lua]: http://lua.org/ "Lua Programming Language"
[Chance.js]: http://chancejs.com/ "Chance JavaScript Library"
[LDoc]: http://stevedonovan.github.io/ldoc/ "Lua Documentation Generator"
[Tup]: http://gittup.org/tup/ "Tup Build System"
[Luacheck]: https://github.com/mpeterv/luacheck "Static Analysis and Lint Tool for Lua"
[ctags]: http://ctags.sourceforge.net/
[Emacs]: https://www.gnu.org/software/emacs/
[Busted]: http://olivinelabs.com/busted/ "Lua Unit Testing Tool"

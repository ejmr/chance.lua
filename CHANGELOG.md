# Change Log

This document describes notable changes to this project, which adheres
to [Semantic Versioning](http://semver.org/).



## Unreleased

### Added

- The `Text` API:
    - `chance.syllable()`
    - `chance.word()`
    - `chance.sentence()`
    - `chance.paragraph()`

- The `Miscellaneous` API:
    - `chance.unique()`

- `unique_array()` assertion for the test suite.

### Changed

- `is_within_range()` is now simply `within_range()`, which makes it
  more flexible for use in assertions.

- The input to `chance.rpg()` is case-insensitive, so one can write
  both `chance.rpg("3d6")` and `chance.rpg("3D6")`.



## [0.2.0] - 2015-08-18

### Added

- The `Core` API:
    - Defining, modifying, and selecting from named data sets
    - `chance.dataSets`
    - `chance.set()`
    - `chance.fromSet()`
    - `chance.appendSet()`

- The `Person` API:
    - `chance.gender()`
    - `chance.age()`
    - `chance.prefix()`
    - `chance.suffix()`

### Changed

- The following functions now randomly select from data sets:
    - `chance.month()` selects from `"months"`
    - `chance.day()` selects from `"days"`



## [0.1.0] - 2015-08-14

### Added

- A basic test suite.

- The `Core` API:
    - `chance.VERSION`
    - `chance.seed()`
    - `chance.random()`

- The `Basic` API:
    - `chance.bool()`
    - `chance.float()`
    - `chance.integer()`
    - `chance.natural()`
    - `chance.character()`

- The `Time` API:
    - `chance.hour()`
    - `chance.minute()`
    - `chance.second()`
    - `chance.millisecond()`
    - `chance.ampm()`
    - `chance.year()`
    - `chance.month()`
    - `chance.timestamp()`
    - `chance.day()`

- The `Helper` API:
    - `chance.pick()`
    - `change.shuffle()`

- The `Miscellaneous` API:
    - `chance.rpg()`
    - `chance.d4()`
    - `chance.d6()`
    - `chance.d8()`
    - `chance.d10()`
    - `chance.d12()`
    - `chance.d20()`
    - `chance.d100()`
    - `chance.n()`

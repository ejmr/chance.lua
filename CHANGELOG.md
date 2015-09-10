# Change Log

This document describes notable changes to this project, which adheres
to [Semantic Versioning](http://semver.org/).



## [0.5.0] - 2015-09-09

## Fixed

- The documentation for `chance.core.fromSet()` now correctly says
  that the `key` parameter can only be a string.  The parameter cannot
  be a function as the documentation erroneously said.

- The documentation for `chance.person.gender()` now correctly
  references `chance.core.dataSets`.

## Added

- The `Helper` API:
    - `chance.helpers.pick_unique()`

- The `Person` API
    - `chance.ssn()`

- The `Poker` API:
    - `chance.poker.card()`
    - `chance.poker.deck()`
    - `chance.poker.hand()`

### Changed

- All API functions now belong to sub-tables named after their
  "section" or group.  For example, `chance.random()` is now
  `chance.core.random()`, `chance.bool()` is now named
  `chance.basic.bool()`, and so on.

- Both `chance.lua` and `chance.spec.lua` now have form feed
  characters that divide up the sections into "pages".



## [0.4.0] - 2015-08-23

### Added

- The `Miscellaneous` API:
    - `chance.normal()`
    - `chance.weighted()`

### Changed

- Improved the documentation for `chance.url()`



## [0.3.0] - 2015-08-22

### Fixed

- `chance.day()` now always returns the correct values when using the
   optional `weekdays` or `weekends` flags.

### Added

- The `Text` API:
    - `chance.syllable()`
    - `chance.word()`
    - `chance.sentence()`
    - `chance.paragraph()`

- The `Miscellaneous` API:
    - `chance.unique()`
    - `chance.hash()`

- The `Web` API:
    - `chance.tld()`
    - `chance.domain()`
    - `chance.email()`
    - `chance.hashtag()`
    - `chance.twitter()`
    - `chance.uri()` and `chance.url()`
    - `chance.color()`
    - `chance.ip()`
    - `chance.ipv6()`

- The Test Suite:
    - The `unique_array()` assertion
    - The `like_pattern()` assertion

- Internal Utilities that are **not** part of the public API:
    - `makeStringFrom()`

### Changed

- `is_within_range()` is now simply `within_range()`, which makes it
  more flexible for use in assertions.

- The input to `chance.rpg()` is case-insensitive, so one can write
  both `chance.rpg("3d6")` and `chance.rpg("3D6")`.

- `chance.day()` accepts both boolean true and false values for the
  optional `weekdays` and `weekends` flags.



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

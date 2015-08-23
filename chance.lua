--[[--

Chance: A Library for Generating Random Data

@module chance
@author Eric James Michael Ritz
@copyright 2015 Plutono Inc
@license GNU General Public License
@release <a href="https://github.com/ejmr/chance.lua">Project Home</a>

--]]--

--- The table representing the entire module.
--
-- @local
local chance = {}

--- Core
--
-- These functions provide a random number generator atop which the
-- rest of the library is built, and metadata about the library.
--
-- @section Core

--- The library version number.
--
-- This table contains four keys: MAJOR, MINOR, PATCH, and LABEL.  The
-- first three are numbers, and the last is a potentially empty
-- string.  Calling <code>tostring()</code> on the table will produce
-- an easy-to-read version number such as "1.0.2-rc1", "2.0.0", etc.
--
-- The version number follows <a href="http://semver.org">Semantic
-- Versioning</a>.
--
-- @field VERSION
chance.VERSION = setmetatable(
    {
        ["MAJOR"] = 0,
        ["MINOR"] = 3,
        ["PATCH"] = 0,
        ["LABEL"] = "-pre-release",
    },
    {
        __tostring = function ()
            return string.format(
                "%i.%i.%i%s",
                chance.VERSION["MAJOR"],
                chance.VERSION["MINOR"],
                chance.VERSION["PATCH"],
                chance.VERSION["LABEL"])
        end
})

--- Make a shallow copy of a table.
--
-- @local
-- @param array
-- @treturn table A copy of <code>array</code>
local function makeShallowCopy(array)
    local copy = {}
    for _,value in ipairs(array) do
        table.insert(copy, value)
    end
    return copy
end

--- Creates a string by calling a generator repeatedly.
--
-- @local
-- @tparam func generator
-- @tparam int|{int,int} count
-- @tparam[opt] string separator
-- @treturn string
local function makeStringFrom(generator, count, separator)
    local amount = count

    if type(count) == "table" then
        amount = chance.random(count[1], count[2])
    end

    return table.concat(chance.n(generator, amount), separator or "")
end

--- Seeds the random number generator.
--
-- This function accepts one parameter: a seed, which it uses to seed
-- the random number generator.  The seed must be a number, and
-- providing the same seed must result in @{chance.random} producing
-- the same sequence of results.  Beyond that there are no
-- restrictions on the implementation of how the seed is used or the
-- underlying random number generation algorithm to be used.
--
-- @tparam Number seed
-- @treturn nil
function chance.seed(seed)
    math.randomseed(seed)
end

--- Returns a random number.
--
-- This is the primary function used throughout the library for
-- generating random numbers.  Any algorithm for generating random
-- numbers may be used, so long as the implementation of this function
-- adheres to the following restrictions:
--
-- 1. When called with no arguments the function must return a number
-- in the range of [0, 1).
--
-- 2. When called with one argument, a number 'm', the function must
-- return a number in the range of [1, m].
--
-- 3. When called with two arguments, numbers 'm' and 'n', the
-- function must return a number in the range of [m, n].  If 'n' is
-- less than or equal to 'm' then the function simply returns 'm'.
--
-- Note that this is the same behavior as <code>math.random()</code>
-- from Lua's standard library.
--
-- @see chance.seed
-- @usage chance.random() == 0.8273
-- @usage chance.random(10) == 7
-- @usage chance.random(8, 12) == 8
--
-- @param[opt] m
-- @param[opt] n
-- @treturn Number
function chance.random(m, n)
    if m ~= nil then
        if n ~= nil then
            if n <= m then
                return m
            else
                return math.random(m, n)
            end
        else
            return math.random(m)
        end
    end
    return math.random()
end

--- Sets of data which some functions choose from.
--
-- Many functions select random data from a predefined source.  For
-- example, @{chance.month} randomly picks a name from an existing
-- list of names.  This table contains all of those types of
-- predefined sets of data.  Developers can modify or add new sets
-- of data by using the @{chance.set} function.
--
-- The keys for this table must strings, which name the data set.
--
-- The values must either be arrays (which can contain any types of
-- values), or a single function.  If the value is a function then the
-- library treats it as a generator for that data set, i.e. the
-- library will invoke that function expecting it to return the
-- appropriate type of random data.  The function will receive no
-- arguments.
--
-- @see chance.set
-- @see chance.fromSet
-- @field dataSets
chance.dataSets = {}

--- Define or modify a set of data.
--
-- This function creates a new set of data or replaces an existing
-- one.  The key parameter must be a string naming the data set.  The
-- data parameter must be either a table of data, which can be of any
-- type, or must be a function.  If it is a function then the library
-- treats it as a generator and will invoke that function with no
-- arguments whenever random data is requested from that set.
--
-- @see chance.fromSet
-- @see chance.dataSets
--
-- @tparam string key
-- @tparam table|function data
-- @treturn nil
function chance.set(key, data)
    chance.dataSets[key] = data
end

--- Add data to an existing data set.
--
-- See the documentation on @{chance.set} for details on the
-- <code>key</code> parameter.  The <code>data</code> must be a table
-- of values which the function will add to the existing data set.
-- <strong>This does not work for data sets that have generator
-- functions for their values.</strong>
--
-- @see chance.set
-- @see chance.dataSets
--
-- @tparam string key
-- @tparam table data
-- @treturn nil
function chance.appendSet(key, data)
    for _,value in ipairs(data) do
        table.insert(chance.dataSets[key], value)
    end
end

--- Select random data from an existing data set.
--
-- See the documentation on @{chance.set} for details on the
-- restrictions and semantics of the <code>key</code> parameter.
--
-- @see chance.set
-- @see chance.dataSets
--
-- @tparam string|function key
-- @return Random data of potentially any type, or nil if there is no
-- data set for the given <code>key</code>
function chance.fromSet(key)
    local data = chance.dataSets[key]

    if data == nil then return nil end

    if type(data) == "function" then
        return data()
    else
        return chance.pick(data)
    end
end

--- Basic
--
-- These are functions that generate simple types of data such as
-- booleans and numbers.
--
-- @section Basic

--- Returns a random boolean.
--
-- If given no arguments the function has a 50/50 chance of returning
-- true or false.  However, an optional table argument can specify the
-- probability of returning true, expressing the probability as a
-- percentage by using an integer in the range [1, 100].
--
-- @usage fifty_fifty = chance.bool()
-- @usage ten_percent_true = chance.bool { probability = 10 }
--
-- @param[opt] flags
-- @treturn true|false
function chance.bool(flags)
    local result = chance.random(100)

    if flags then
        return result <= flags["probability"]
    else
        return result <= 50
    end
end

--- Returns a random floating-point number.
--
-- The number will be in the range of zero (inclusive) to one
-- (exclusive), like random number generating functions in many
-- programming languages.
--
-- @treturn number
function chance.float()
    return chance.random()
end

--- Returns a random integer.
--
-- By default the function returns an integer between smallest and the
-- largest integers Lua allows on the given platform.  An optional
-- table can provide inclusive "min" and "max" limits, which have the
-- default values -2^16 and 2^16, respectively.
--
-- @usage x = chance.integer()
-- @usage y = chance.integer { max = 50 }
-- @usage z = chance.integer { min = 1, max = 20 }
--
-- @param[opt] flags
-- @treturn int
function chance.integer(flags)
    local min, max = -2^16, 2^16

    if flags then
        if flags["min"] then min = flags["min"] end
        if flags["max"] then max = flags["max"] end
    end

    return chance.random(min, max)
end

--- Returns a random natural number.
--
-- By default the function returns a number between zero and positive
-- inifinity.  But it accepts an optional table of flags which can
-- define inclusive "min" and "max" ranges for the result.  Minimum
-- values less than zero are rounded up to zero.
--
-- @see chance.integer
--
-- @param[opt] flags
-- @treturn int
function chance.natural(flags)
    if flags then
        if (flags["min"] == nil) or (flags["min"] and flags["min"] < 0) then
            flags["min"] = 0
        end
        return chance.integer(flags)
    end
    return chance.integer { min = 0 }
end

-- These groups are preset "pools" for chance.character().
local character_groups = {}
character_groups["lower"]  = "abcdefghijklmnopqrstuvwxyz"
character_groups["upper"]  = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
character_groups["digit"]  = "0123456789"
character_groups["hex"]    = "0123456789abcdef"
character_groups["letter"] = character_groups["lower"]  .. character_groups["upper"]
character_groups["all"]    = character_groups["letter"] .. character_groups["digit"]

--- Returns a random character.
--
-- This functions returns a random character which will be either a
-- digit or a letter, lower-case and upper-case.
--
-- The function accepts a table of optional flags.  The "pool" flag
-- can be a string from which the function will select a character.
-- Or one can use the "group" flag to receive a random character from
-- a specific group of characters.  The acceptable group names are
-- "lower", "upper", "letter" (case-insensitive), "digit", and "all"
-- (the default).  If the function receives both "pool" and "group"
-- then "pool" takes precedence and "group" is ignored.
--
-- @usage anything = chance.character()
-- @usage anything = chance.character { group = "all" }
-- @usage vowel = chance.character { pool = "aeiou" }
-- @usage capital = chance.character { group = "upper" }
--
-- @param[opt] flags
-- @treturn string
function chance.character(flags)
    local pool = character_groups["all"]

    if flags then
        if flags["pool"] then
            pool = flags["pool"]
        elseif flags["group"] then
            pool = character_groups[flags["group"]]
        end
    end

    local index = chance.random(pool:len())
    return pool:sub(index, index)
end

--- Returns a random string.
--
-- This function will return a string of random characters, with a
-- random length of five to twenty characters.  The optional flags
-- table can set "length" explicitly.  It also accepts a "group" flag
-- which determines what kind of characters appear in the string.
--
-- @see chance.character
--
-- @usage chance.string() == "c0Ab3le8"
-- @usage chance.string { length = 3 } == "NIN"
-- @usage chance.string { group = "digit" } = "8374933749"
--
-- @param[opt] flags
-- @treturn string
function chance.string(flags)
    local length = chance.random(5, 20)
    local group = "all"
    local result = ""

    if flags then
        if flags["length"] then
            length = flags["length"]
        end

        if flags["group"] then
            group = flags["group"]
        end
    end

    local count = 1
    while count <= length do
        result = result .. chance.character { group = group }
        count = count + 1
    end

    return result
end

--- Text
--
-- These are functions for generating random text.
--
-- @section Text

--- Data used to build random syllables.
--
-- @see chance.syllable
-- @local
-- @field syllables
-- @table chance.dataSets
chance.set("syllables", {
        ["consonants"] = {
            "b",
            "c",
            "ch",
            "d",
            "f",
            "g",
            "gh",
            "h",
            "j",
            "k",
            "l",
            "m",
            "n",
            "p",
            "qu",
            "r",
            "s",
            "sh",
            "t",
            "th",
            "y",
            "w",
            "z",
        },
        ["vowels"] = {
            "a",
            "e",
            "i",
            "o",
            "u",
            "ea",
            "ee",
            "ao",
            "oo",
            "ou",
        }})

--- Returns a random syllable.
--
-- This functions returns a randomly generated syllable that will be
-- between two to six characters in length.  It uses the
-- <code>syllables</code> data set, which contains a collection of
-- consonants and vowels used to create the syllable.  Each syllable
-- will contain between two to six characters.
--
-- @usage chance.syllable() == "peep"
-- @see chance.word
--
-- @treturn string
function chance.syllable()
    local initial = chance.pick(chance.dataSets["syllables"]["consonants"])
    local vowel = chance.pick(chance.dataSets["syllables"]["vowels"])
    local ending = chance.pick(chance.dataSets["syllables"]["consonants"])
    local syllable = initial .. vowel

    -- Fifty percent of the time we add an additional consonant sound
    -- to the end of the syllable.
    if chance.bool() == true then
        syllable = syllable .. ending
    end

    return syllable
end

--- Returns a random word.
--
-- The word, by default, will contain one to three syllables.
-- However, the optional flag <code>syllables</code> can specify
-- exactly how many syllables to use in the word.  Note that
-- "syllable" in this context means anything which @{chance.syllable}
-- will return.
--
-- @usage chance.word() == "beepbop"
-- @usage chance.word { syllables = 4 } == "thadoobgerlu"
-- @see chance.syllable
--
-- @param[opt] flags
-- @treturn string
function chance.word(flags)
    local syllableCount = chance.random(1, 3)
    local word = ""

    if flags and flags["syllables"] then
        syllableCount = flags["syllables"]
    end

    if syllableCount < 1 then return word end

    while syllableCount > 0 do
        syllableCount = syllableCount - 1
        word = word .. chance.syllable()
    end

    return word
end

--- Generates a random sentence of words via @{chance.word}.
--
-- This function returns a sentence of random words, between twelve to
-- eighteen words by default.  The optional <code>words</code> flag
-- allows controling exactly how many words appear in the sentence.
-- The first word in the sentence will be capitalized and the sentence
-- will end with a period.
--
-- @usage chance.sentence { words = 3 } == "Hob the rag."
-- @see chance.word
--
-- @param[opt] flags
-- @treturn string
function chance.sentence(flags)
    local words
    local wordCount = chance.random(12, 18)

    if flags and flags["words"] then
        wordCount = flags["words"]
    end

    words = chance.n(chance.word, wordCount)
    words[1] = string.gsub(words[1], "^%l", string.upper)
    table.insert(words, ".")

    return table.concat(words, " ")
end

--- Generates a random paragraph via @{chance.sentence}.
--
-- This function returns a paragraph of random sentences, created by
-- calling @{chance.sentence}.  By default the paragraph will contain
-- three to seven sentences.  However, the optional integer flag
-- <code>sentences</code> controls exactly how many sentences to
-- create for the paragraph.
--
-- @see chance.sentence
--
-- @param[opt] flags
-- @treturn string
function chance.paragraph(flags)
    local count = chance.random(3, 7)

    if flags and flags["sentences"] then
        count = flags["sentences"]
    end

    return makeStringFrom(chance.sentence, count)
end

--- Person
--
-- These are functions for generating random data about people.
--
-- @section Person

--- The possible genders returned by @{chance.gender}.
--
-- This is a table of strings which the @{chance.gender} function will
-- randomly choose from when called.  Developers can modify the domain
-- of @{chance.gender} by changing this table to include or remove
-- possible values as needed for their purposes.  The default values
-- are based on common gender identities in modern socities as opposed
-- to gender based on medical qualification (e.g. chromosones) or
-- sexual orientation.
--
-- @see chance.gender
-- @local
-- @field genders
-- @table chance.dataSets
chance.set("genders", {
    "Male",
    "Female",
    "Third", -- https://en.m.wikipedia.org/wiki/Third_gender
})

--- Returns a random gender as a string.
--
-- One can classify gender in a number of ways.  The most traditional
-- form is the binary division of 'male' and 'female'; if the function
-- is given the optional flag <code>binary = true</code> then it will
-- return either <code>"Male"</code> or <code>"Female"</code>.
--
-- By default, however, the function will return a string from the
-- <code>genders</code> data set.
--
-- @usage chance.gender() == "Female"
-- @usage chance.gender { binary = true } == "Male"
--
-- @see chance.genders
--
-- @param[opt] flags
-- @treturn string
function chance.gender(flags)
    if flags and flags["binary"] == true then
        return chance.pick { "Male", "Female" }
    end
    return chance.fromSet("genders")
end

--- Possible words returned by @{chance.prefix}
--
-- @see chance.prefix
-- @local
-- @field prefixes
-- @table chance.dataSets
chance.set("prefixes", {
        ["short"] = {
            "Mr.",
            "Ms.",
            "Mrs.",
            "Doc.",
            "Prof.",
            "Rev.",
            "Hon.",
        },
        ["long"] = {
            "Mister",
            "Miss",
            "Doctor",
            "Professor",
            "Reverend",
            "Honorable",
        }})

--- Returns a random prefix for a name.
--
-- This function will return a random prefix for a name, e.g. "Mr."
-- or "Prof.", short prefixes by default.  The function accepts an
-- optional table of flags, and if the flag <code>type</code> equals
-- <code>"long"</code> then the function returns prefixes such as
-- "Mister" and "Professor".  The function uses the
-- <code>prefixes</code> data set.
--
-- @usage chance.prefix() == "Mrs."
-- @usage chance.prefix { type = "long" } == "Doctor"
--
-- @param[opt] flags
-- @treturn string
function chance.prefix(flags)
    local prefixType = "short"
    if flags and flags["type"] then
        prefixType = string.lower(flags["type"])
    end
    return chance.pick(chance.dataSets["prefixes"][prefixType])
end

--- Possible words returned by @{chance.suffix}
--
-- @see chance.suffix
-- @local
-- @field suffixes
-- @table chance.dataSets
chance.set("suffixes", {
        ["short"] = {
            "Ph.D.",
            "Esq.",
            "Jr.",
            "Sr.",
            "M.D.",
            "J.D.",
        },
        ["long"] = {
            "Doctor of Philosophy",
            "Esquire",
            "Junior",
            "Senior",
            "Medical Doctor",
            "Juris Doctor",
        },
    }
)

--- Returns a random suffix for names.
--
-- This function will return a random suffix for a name, e.g. "Jr."
-- or "M.D.", short prefixes by default.  The function accepts an
-- optional table of flags, and if the flag <code>type</code> equals
-- <code>"long"</code> then the function returns prefixes such as
-- "Junior" and "Juris Doctor".  The function uses the
-- <code>suffixes</code> data set.
--
-- @usage chance.suffix() == "Sr."
-- @usage chance.suffix { type = "long" } == "Senior"
--
-- @param[opt] flags
-- @treturn string
function chance.suffix(flags)
    local suffixType = "short"
    if flags and flags["type"] then
        suffixType = string.lower(flags["type"])
    end
    return chance.pick(chance.dataSets["suffixes"][suffixType])
end

--- Ranges for various types of ages.
--
-- @see chance.age
-- @local
-- @field ages
-- @table chance.dataSets
chance.set("ages", {
        ["child"]  = {1, 12},
        ["teen"]   = {13, 19},
        ["adult"]  = {18, 65},
        ["senior"] = {65, 100},
    })

--- Returns a random age for a person.
--
-- By default this function return an integer in the range of one and
-- one-hundred twenty.  It accepts an optional <code>type</code> flag
-- which must be one of the following strings, which limit the range
-- of the generated age:
--
-- <ol>
-- <li><code>"child" = [1, 12]</code></li>
-- <li><code>"teen" = [13, 19]</code></li>
-- <li><code>"adult" = [18, 65]</code></li>
-- <li><code>"senior" = [65, 100]</code></li>
-- </ol>
--
-- These ranges are defined in the <code>ages</code> data set, meaning
-- one can use @{chance.set} and @{chance.appendSet} to redefine the
-- ranges for types and/or add new types.
--
-- @usage chance.age() == 33
-- @usage chance.age { type = "teen" } == 17
-- @usage chance.age { type = "adult" } == 40
--
-- @param[opt] flags
-- @treturn int
function chance.age(flags)
    if flags and flags["type"] then
        local group = chance.dataSets["ages"][flags["type"]]
        return chance.random(group[1], group[2])
    end
    return chance.random(1, 120)
end

--- Time
--
-- These are functions for generating random times.
--
-- @section Time

--- Returns a random hour.
--
-- By default this will return an hour in the range of one to twelve.
-- However, if the optional flag <code>twentyfour</code> is true then
-- the result will be in the range of one to twenty-four.
--
-- @usage chance.hour() == 3
-- @usage chance.hour { twentyfour = true } == 15
--
-- @param[opt] flags
-- @treturn number
function chance.hour(flags)
    if flags and flags["twentyfour"] == true then
        return chance.random(1, 24)
    else
        return chance.random(1, 12)
    end
end

--- Returns a random minute.
--
-- This will return a number in the range of zero to fifty-nine.
--
-- @treturn number
function chance.minute()
    return chance.random(0, 59)
end

--- Returns a random second.
--
-- This will return a number in the range of zero to fifty-nine.
--
-- @treturn number
function chance.second()
    return chance.random(0, 59)
end

--- Returns a random millisecond.
--
-- This returns a number in the range of zero to nine-hundred ninety
-- nine.
--
-- @treturn number
function chance.millisecond()
    return chance.random(0, 999)
end

--- Returns a random year.
--
-- By default this function returns a number representing a year in
-- the range of the current year and a century later.  For example,
-- calling <code>chance.year()</code> in the year 2015 will return
-- a number between 2015 and 2115.
--
-- The function accepts an optional table of flags which can have
-- <code>min</code> and <code>max</code> properties to restrict the
-- range of the output.  If only <code>min</code> is provided then the
-- maximum range is one century ahead of the minimum, for example
-- <code>chance.year { min = 1750 }</code> returns a year between 1750
-- and 1850.  If only <code>max</code> is provided then the minimum is
-- the current year.
--
-- @usage chance.year() == 2074
-- @usage chance.year { min = 1800 } == 1884
-- @usage chance.year { max = 2300 } == 2203
-- @usage chance.year { min = 1990, max = 2000 } == 1995
--
-- @param[opt] flags
-- @treturn number
function chance.year(flags)
    local current_year = os.date("*t")["year"]
    local minimum = current_year
    local maximum = current_year + 100

    if flags then
        if flags["min"] and flags["max"] then
            minimum = flags["min"]
            maximum = flags["max"]
        elseif flags["min"] then
            minimum = flags["min"]
            maximum = minimum + 100
        elseif flags["max"] then
            maximum = flags["max"]
        end
    end

    return chance.random(minimum, maximum)
end

--- Names of months.
--
-- @see chance.month
-- @local
-- @field months
-- @table chance.dataSets
chance.set("months", {
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December",
})

--- Returns the name of a random month.
--
-- This function chooses the name of a month from the
-- <code>months</code> data set.
--
-- @treturn string
function chance.month()
    return chance.fromSet("months")
end

--- Names of days of the week.
--
-- @see chance.day
-- @local
-- @field days
-- @table chance.dataSets
chance.set("days", {
        ["weekdays"] = {
            "Monday",
            "Tuesday",
            "Wednesday",
            "Thursday",
            "Friday",
        },
        ["weekends"] = {
            "Saturday",
            "Sunday",
        }})

--- Returns a random day of the week.
--
-- By default this function will return the name of a day of the week,
-- chosen from the <code>days</code> data set.  The function accepts
-- an optional table of flags which control the possible days it
-- returns.  The optional boolean flags <code>weekdays</code> and
-- <code>weekends</code> will restrict the output to those types of
-- days.
--
-- @usage chance.day() == "Monday"
-- @usage chance.day { weekends = true } == "Sunday"
-- @usage chance.day { weekends = false } == "Thursday"
--
-- @param[opt] flags
-- @treturn string
function chance.day(flags)
    local category = "all"
    local days = {}

    if flags then
        if flags["weekdays"] == false
        or flags["weekends"] == true then
            category = "weekends"
        elseif flags["weekends"] == false
        or flags["weekdays"] == true then
            category = "weekdays"
        end
    end

    if category == "weekdays" or category == "weekends" then
        days = makeShallowCopy(chance.dataSets["days"][category])
    elseif category == "all" then
        for _,set in pairs(chance.dataSets["days"]) do
            for _,day in ipairs(set) do
                table.insert(days, day)
            end
        end
    end

    return chance.pick(days)
end

--- Returns a random Unix timestamp.
--
-- This function returns a random number between zero and the current
-- time as a Unix timestamp, i.e. the number of seconds since January
-- 1st 1970.
--
-- <strong>This function may not correctly determine the current time
-- on non-POSIX systems.</strong>
--
-- @treturn number
function chance.timestamp()
    return chance.random(0, os.time())
end

--- Returns 'am' or 'pm' for use with times.
--
-- @treturn string <code>"am"</code> or <code>"pm"</code>
function chance.ampm()
    local probability = chance.random()

    if probability < 0.5 then
        return "am"
    else
        return "pm"
    end
end

--- Web
--
-- These are functions for generating random data related to the World
-- Wide Web.
--
-- @section Web

--- Returns a random color for use in HTML and CSS.
--
-- This function returns a random color (as a string) suitable for use
-- in HTML or Cascading Style Sheets.  By default the function returns
-- a color in six-digit hex notation, e.g <code>#a034cc</code>.
-- However, the optional flag <code>format</code> can affect the
-- representation of the color via the following values:
--
-- <ol>
-- <li><code>hex</code> e.g. <code>#a034cc</code> (Default)</li>
-- <li><code>shorthex</code> e.g. <code>#3ca</code></li>
-- <li><code>rgb</code> e.g. <code>rgb(120, 80, 255)</code></li>
-- </ol>
--
-- If the flag <code>greyscale</code> is true then the function
-- generates a greyscale color.  The flag <code>grayscale</code> (with
-- an 'a') is an acceptable alias.
--
-- @usage chance.color() == "#a034cc"
-- @usage chance.color { format = "shorthex" } == "#eeb"
-- @usage chance.color { format = "rgb" } == "rgb(120, 80, 255)"
-- @usage chance.color { greyscale = true } == "#3c3c3c"
--
-- @param[opt] flags
-- @treturn string
function chance.color(flags)
    local red, green, blue = unpack(chance.n(chance.string, 3, { length = 2, group = "hex" }))

    if flags then
        if flags["format"] == "shorthex" then
            red, green, blue = unpack(chance.n(chance.string, 3, { length = 1, group = "hex" }))
        elseif flags["format"] == "rgb" then
            red, green, blue = unpack(chance.n(chance.natural, 3, { min = 0, max = 255 }))
        end

        if flags["greyscale"] or flags["grayscale"] then
            green = red
            blue = red
        end
    end

    if flags and flags["format"] == "rgb" then
        return string.format("rgb(%i, %i, %i)", red, green, blue)
    else
        return "#" .. red .. green .. blue
    end
end

--- Generates a random IP address.
--
-- This function generates a random IPv4 address and returns it as a
-- string.  By default the four octets can have any value in the range
-- <code>[0,255]</code>.  However, the function accepts optional flags
-- that will create addresses of a specific class, or addresses with
-- explicit values for certain octets.
--
-- @usage chance.ip() == "132.89.0.200"
-- @usage chance.ip { class = "B" } == "190.1.24.30"
-- @usage chance.ip { octets = { 192, 128 }} == "192.128.0.1"
--
-- @see chance.ipv6
--
-- @param[opt] flags
-- @treturn string
function chance.ip(flags)
    local octets = chance.n(chance.natural, 4, { max = 255 })
    local rangesForClass = {
        ["A"] = {0, 127},
        ["B"] = {128, 191},
        ["C"] = {192, 223},
    }

    if flags then
        if flags["class"] then
            local range = rangesForClass[string.upper(flags["class"])]
            octets[1] = chance.random(range[1], range[2])
        end
        if flags["octets"] then
            for index,value in ipairs(flags["octets"]) do
                octets[index] = value
            end
        end
    end

    return string.format("%i.%i.%i.%i",
                         octets[1],
                         octets[2],
                         octets[3],
                         octets[4])
end

--- Generates a random IPv6 address.
--
-- @see chance.ip
--
-- @treturn string
function chance.ipv6()
    local octet = function ()
        return chance.string { length = 4, group = "hex" }
    end
    return makeStringFrom(octet, 8, ":")
end

--- Top-Level Domains
--
-- @see chance.tld
-- @local
-- @field tlds
-- @table chance.dataSets
chance.set("tlds", {
        "com",
        "org",
        "net",
        "edu",
        "gov",
        "int",
        "mil",
})

--- Generate a random top-level domain.
--
-- This function returns a random top-level domain as a string.  It
-- chooses a domain from the <code>tlds</code> data set.
--
-- @usage chance.tld() == "net"
--
-- @treturn string
function chance.tld()
    return chance.fromSet("tlds")
end

--- Generate a random domain.
--
-- This function returns a random web domain.  By default the domain
-- name contains one to three words and a random top-level domain.
-- The optional flag <code>words</code> controls exactly how many
-- words appear in the domain, and the flag <code>tld</code> will
-- ensure the result uses that specific top-level domain.
--
-- @usage chance.domain() == "paroo.net"
-- @usage chance.domain { words = 1 } == "fee.gov"
-- @usage chance.domain { tld = "co.bh" } == "havashi.co.bh"
--
-- @see chance.word
-- @see chance.tld
--
-- @param[opt] flags
-- @treturn string
function chance.domain(flags)
    local wordCount = chance.random(1, 3)
    local tld = chance.tld()

    if flags then
        if flags["words"] then
            wordCount = flags["words"]
        end
        if flags["tld"] then
            tld = flags["tld"]
        end
    end

    return makeStringFrom(chance.word, wordCount) .. "." .. tld
end

--- Returns a random email address.
--
-- This function will return an email address consisting of random
-- words, belonging to a random domain.  The optional flag
-- <code>domain</code> can specify the exact domain to use.
--
-- @usage chance.email() == "foo@boohoo.edu"
-- @usage chance.email { domain = "example.com" } == "lepiwoa@example.com"
--
-- @see chance.word
-- @see chance.domain
--
-- @param[opt] flags
-- @treturn string
function chance.email(flags)
    local name = chance.word()
    local domain = chance.domain()

    if flags and flags["domain"] then
        domain = flags["domain"]
    end

    return name .. "@" .. domain
end

--- Returns a random Twitter hashtag.
--
-- This function returns a string representing a Twitter hashtag.  The
-- string will begin with the '#' character and contain one to three
-- random words.
--
-- @usage chance.hashtag() == "#namarob"
-- @see chance.twitter
--
-- @treturn string
function chance.hashtag()
    return "#" .. makeStringFrom(chance.word, {1, 3})
end

--- Generates a random Twitter handle.
--
-- This function returns a string representing a random Twitter
-- account name.  The string will begin with '@' followed by one to
-- five words.
--
-- @usage chance.twitter() == "@meepboat"
-- @see chance.hashtag
--
-- @treturn string
function chance.twitter()
    return "@" .. makeStringFrom(chance.word, {1, 5})
end

--- Generates a random URI.
--
-- This function returns a random URI.  By default it uses the
-- <code>http</code> protocol, with random names generated for the
-- domain and path.  The function accepts a number of optional flags
-- though:
--
-- <ul>
-- <li><code>domain</code> - Sets an explicit domain name.</li>
-- <li><code>path</code> - Sets an explicit path.</li>
-- <li><code>protocol</code> Sets an explicit protocol.</li>
-- <li><code>extensions</code> - Uses one of the given extensions.</li>
-- </ul>
--
-- @usage chance.uri() == "http://foobar.net/baz"
-- @usage chance.uri { domain = "example.com" } == "http://example.com/wee"
-- @usage chance.uri { path = "foo/bar" } == "http://narofu.edu/foo/bar"
-- @usage chance.uri { extensions = { "png", "gif" }} == "http://benhoo.gov/dao.png"
-- @usage chance.uri { protocol = "ftp" } == "ftp://fufoo.net/veto"
--
-- @see chance.domain
--
-- @param[opt] flags
-- @treturn string
function chance.uri(flags)
    local protocol = "http"
    local domain = chance.domain()
    local path = makeStringFrom(chance.word, {1, 2})
    local extensions = {}

    if flags then
        if flags["protocol"] then
            protocol = flags["protocol"]
        end
        if flags["domain"] then
            domain = flags["domain"]
        end
        if flags["path"] then
            path = flags["path"]
        end
        if flags["extensions"] then
            extensions = flags["extensions"]
        end
    end

    local uri = protocol .. "://" .. domain .. "/" .. path

    if #extensions > 0 then
        uri = uri .. chance.pick(extensions)
    end

    return uri
end

--- Generates a random URL.
--
-- This function is an alias for @{chance.uri}.
--
-- @param[opt] flags
-- @treturn string
-- @function chance.url
chance.url = chance.uri

--- Miscellaneous
--
-- These are functions for generating data which does not easily fall
-- under any other category.
--
-- @section Miscellaneous

--- Returns a normally-distributed random value.
--
-- By default the function returns a value with a mean of zero and a
-- standard deviation of one.  However, the optional flags
-- <code>mean</code> and <code>deviation</code> can provide different
-- values to use for each.
--
-- @usage chance.normal() == 0.2938473
-- @usage chance.normal { mean = 100 } == 99.172493
-- @usage chance.normal { mean = 100, deviation = 15 } == 85.83741
--
-- @param[opt] flags
-- @treturn number
function chance.normal(flags)
    local mean, deviation = 0, 1

    if flags then
        if flags["mean"] then
            mean = flags["mean"]
        end
        if flags["dev"] then
            deviation = flags["dev"]
        end
    end

    -- The Marsaglia Polar Method
    -- https://en.wikipedia.org/wiki/Marsaglia_polar_method
    local s, u, v

    repeat
        u = chance.random() * 2 - 1
        v = chance.random() * 2 - 1
        s = u * u + v * v
    until s < 1

    local normal = u * math.sqrt(-2 * math.log(s) / s)

    return deviation * normal + mean
end

--- Randomly selects an item from an array of weighted values.
--
-- This function accepts two arrays: the first a table of values to
-- select from, and the second a table of numbers indicating the
-- weight for each value, i.e. the probability the function will
-- select that value.  <strong>If the two arguments are not tables of
-- the same length then the function returns <code>nil<code>.</strong>
--
-- @usage chance.weighted({"a", "b"}, {100, 1})
-- -- This will return "a" one-hundred times more often than
-- -- it will return "b".
--
-- @tparam table values
-- @tparam table weights
-- @return A element from the <code>values</code> array
function chance.weighted(values, weights)
    if #values ~= #weights then return nil end

    local sum = 0
    for _,weight in ipairs(weights) do
        sum = sum + weight
    end

    local chosenIndex = chance.natural { min = 1, max = sum }
    local total = 0
    for index,weight in ipairs(weights) do
        if chosenIndex <= total + weight then
            chosenIndex = index
            break
        else
            total = total + weight
        end
    end

    return values[chosenIndex]
end

--- Create an array of random data from a given generator.
--
-- This function requires two arguments: a function which generates
-- random data, and a number.  The function will invoke the generator
-- that number of times and return an array of that size containing
-- whatever random data comes out of the generator.  Effectively this
-- function acts as a shortcut for writing a for-loop that calls a
-- <code>chance.*()</code> function a certain number of times while
-- collecting the results into an array.
--
-- Any additional arguments will be given to the generator function on
-- each invocation.
--
-- @usage switches = chance.n(chance.bool, 3)
-- @usage numbers = chance.n(chance.natural, 10, { max = 100 })
--
-- @param generator A function that returns random data.
-- @param count The number of times to call the generator.
-- @param[opt] ... Additional arguments passed to the generator.
-- @treturn table
function chance.n(generator, count, ...)
    local results = {}

    if count <= 0 then return results end
    while count > 0 do
        table.insert(results, generator(...))
        count = count - 1
    end

    return results
end

--- Creates an array of unique values from a given generator.
--
-- This function is similar to @{chance.n} in that it accepts a
-- generator function, often another <code>chance</code> function, and
-- a number of items to generate.  The function will return an array
-- containing that many items, randomly generated by the given
-- function.  However, unlike @{chance.n}, the items in the array are
-- guaranteed to be unique.
--
-- Any additional arguments will be given to the generator function on
-- each invocation.
--
-- @usage chance.unique(chance.month, 3) == { "May", "February", "April" }
-- @usage chance.unique(chance.character, 2, { pool = "aeiou" }) == { "e", "u" }
--
-- @param generator A function that returns random data.
-- @param count The number of times to call the generator.
-- @param[opt] ... Additional arguments passed to the generator.
-- @treturn table
function chance.unique(generator, count, ...)
    local results = {}
    local alreadyExists = function (datum)
        for _,value in ipairs(results) do
            if value == datum then return true end
        end
        return false
    end

    if count <= 0 then return results end
    while count > 0 do
        local datum = generator(...)
        if alreadyExists(datum) == false then
            table.insert(results, datum)
            count = count - 1
        end
    end

    return results
end

--- Create a random hash in hexadecimal.
--
-- This function returns a string representing a hash as a hexadecimal
-- number.  By default the function returns a number with 40 digits
-- (i.e. a string with 40 characters), but the optional flag
-- <code>digits</code> can specify exactly how many digits the hash
-- will have.
--
-- @usage chance.hash() == "9f3cbf2466d865d82310b9b1e785401556daedce"
-- @usage chance.hash { digits = 8 } == "5d82310b"
--
-- @param[opt] flags
-- @treturn string
function chance.hash(flags)
    local digits = 40

    if flags and flags["digits"] then
        digits = flags["digits"]
    end

    return chance.string { group = "hex", length = digits }
end

--- Create an array of die rolls using Dungeons and Dragons notation.
--
-- This function returns an array of random numbers simulating the
-- results of rolling dice of the kind found in most table-top RPGs
-- such as Dungeons and Dragons.  The argument to the function must be
-- a string of the form <code>#d#</code> (case-insensitive) where each
-- <code>#</code> is a number; the first represents the number of
-- rolls to make, and the second represents the number of sides on the
-- die, e.g. <code>3d6</code> returns an array with three numbers,
-- each being the result of rolling a six-sided die.
--
-- @usage chance.rpg("1d8") == {4}
-- @usage chance.rpg("3d20") == {10, 4, 17}
--
-- @param notation
-- @treturn table The values of each die roll.
function chance.rpg(notation)
    local _,middle = notation:lower():find("d")
    local rolls = tonumber(notation:sub(1, middle - 1))
    local die = tonumber(notation:sub(middle + 1))
    local results = {}

    while rolls > 0 do
        table.insert(results, chance.random(1, die))
        rolls = rolls - 1
    end

    return results
end

--- Create a short-cut function for rolling dice.
--
-- This utility function accepts a die as a string, i.e. the number of
-- sides on the die, and creates a public API function which returns
-- one number by rolling that die.  For example, after calling...
--
--     createDieRollFunction("10")
--
-- ...we end up with the function chance.d10(), which will return the
-- result of rolling a ten-sided die once.
--
-- @local
local function createDieRollFunction(die)
    chance["d" .. die] = function ()
        local roll = chance.rpg("1d" .. die)
        return roll[1]
    end
end

--- Roll a 4-sided die.
--
-- @function chance.d4
-- @treturn number
createDieRollFunction("4")

--- Roll a 6-sided die.
--
-- @function chance.d6
-- @treturn number
createDieRollFunction("6")

--- Roll an 8-sided die.
--
-- @function chance.d8
-- @treturn number

createDieRollFunction("8")
--- Roll a 10-sided die.
--
-- @function chance.d10
-- @treturn number

createDieRollFunction("10")
--- Roll a 12-sided die.
--
-- @function chance.d12
-- @treturn number

createDieRollFunction("12")
--- Roll a 20-sided die.
--
-- @function chance.d20
-- @treturn number
createDieRollFunction("20")

--- Roll a 100-sided die.
--
-- @function chance.d100
-- @treturn number
createDieRollFunction("100")

--- Helpers
--
-- These are functions that help select random data from existing
-- sources or define new random content generation functions.
--
-- @section Helpers

--- Pick a random element from a given array.
--
-- This function takes a table with numeric keys and randomly returns
-- a value assigned to one of those keys.  The function optionally
-- accepts an integer <code>count</code> which, if given, will return
-- a new table containing that many values.
--
-- @param array
-- @param[opt] count
--
-- @return A single value from <code>array</code> or a table of the
-- size <code>count</code> containing random values from
-- <code>array</code>.
function chance.pick(array, count)
    local size = #array

    if count ~= nil and count > 0 then
        local results = {}
        while count > 0 do
            table.insert(results, array[chance.random(1, size)])
            count = count - 1
        end
        return results
    end

    return array[chance.random(1, size)]
end

--- Randomly shuffle the contents of an array.
--
-- This function takes an array, i.e. a table with only numeric
-- indices, and returns a new table of the same size and with those
-- same elements except in a random order.  Naturally there is the
-- possibility that the shuffled array will be randomly,
-- coincidentally equal to the original.
--
-- @usage chance.shuffle {"foo", "bar", "baz"} == {"bar", "foo", "baz"}
--
-- @param array
-- @treturn table
function chance.shuffle(array)
    local original = makeShallowCopy(array)
    local shuffled = {}
    local count = #original

    while count > 0 do
        local position = chance.random(1, count)
        table.insert(shuffled, original[position])
        table.remove(original, position)
        count = count - 1
    end

    return shuffled
end

-- Return the module.  This should always be the final line of code.
return chance

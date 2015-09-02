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

chance.core = {}

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
        ["MINOR"] = 5,
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
        amount = chance.core.random(count[1], count[2])
    end

    return table.concat(chance.misc.n(generator, amount), separator or "")
end

--- Seeds the random number generator.
--
-- This function accepts one parameter: a seed, which it uses to seed
-- the random number generator.  The seed must be a number, and
-- providing the same seed must result in @{chance.core.random}
-- producing the same sequence of results.  Beyond that there are no
-- restrictions on the implementation of how the seed is used or the
-- underlying random number generation algorithm to be used.
--
-- @tparam Number seed
-- @treturn nil
function chance.core.seed(seed)
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
-- @see chance.core.seed
-- @usage chance.core.random() == 0.8273
-- @usage chance.core.random(10) == 7
-- @usage chance.core.random(8, 12) == 8
--
-- @param[opt] m
-- @param[opt] n
-- @treturn Number
function chance.core.random(m, n)
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
-- example, @{chance.time.month} randomly picks a name from an
-- existing list of names.  This table contains all of those types of
-- predefined sets of data.  Developers can modify or add new sets of
-- data by using the @{chance.core.set} function.
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
-- @see chance.core.set
-- @see chance.core.fromSet
-- @field dataSets
chance.core.dataSets = {}

--- Define or modify a set of data.
--
-- This function creates a new set of data or replaces an existing
-- one.  The key parameter must be a string naming the data set.  The
-- data parameter must be either a table of data, which can be of any
-- type, or must be a function.  If it is a function then the library
-- treats it as a generator and will invoke that function with no
-- arguments whenever random data is requested from that set.
--
-- @see chance.core.fromSet
-- @see chance.core.dataSets
--
-- @tparam string key
-- @tparam table|function data
-- @treturn nil
function chance.core.set(key, data)
    chance.core.dataSets[key] = data
end

--- Add data to an existing data set.
--
-- See the documentation on @{chance.core.set} for details on the
-- <code>key</code> parameter.  The <code>data</code> must be a table
-- of values which the function will add to the existing data set.
-- <strong>This does not work for data sets that have generator
-- functions for their values.</strong>
--
-- @see chance.core.set
-- @see chance.core.dataSets
--
-- @tparam string key
-- @tparam table data
-- @treturn nil
function chance.core.appendSet(key, data)
    for _,value in ipairs(data) do
        table.insert(chance.core.dataSets[key], value)
    end
end

--- Select random data from an existing data set.
--
-- See the documentation on @{chance.core.set} for details on the
-- restrictions and semantics of the <code>key</code> parameter.
--
-- @see chance.core.set
-- @see chance.core.dataSets
--
-- @tparam string key
-- @return Random data of potentially any type, or nil if there is no
-- data set for the given <code>key</code>
function chance.core.fromSet(key)
    local data = chance.core.dataSets[key]

    if data == nil then return nil end

    if type(data) == "function" then
        return data()
    else
        return chance.helpers.pick(data)
    end
end


--- Basic
--
-- These are functions that generate simple types of data such as
-- booleans and numbers.
--
-- @section Basic

chance.basic = {}

--- Returns a random boolean.
--
-- If given no arguments the function has a 50/50 chance of returning
-- true or false.  However, an optional table argument can specify the
-- probability of returning true, expressing the probability as a
-- percentage by using an integer in the range [1, 100].
--
-- @usage fifty_fifty = chance.basic.bool()
-- @usage ten_percent_true = chance.basic.bool { probability = 10 }
--
-- @param[opt] flags
-- @treturn true|false
function chance.basic.bool(flags)
    local result = chance.core.random(100)

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
function chance.basic.float()
    return chance.core.random()
end

--- Returns a random integer.
--
-- By default the function returns an integer between smallest and the
-- largest integers Lua allows on the given platform.  An optional
-- table can provide inclusive "min" and "max" limits, which have the
-- default values -2^16 and 2^16, respectively.
--
-- @usage x = chance.basic.integer()
-- @usage y = chance.basic.integer { max = 50 }
-- @usage z = chance.basic.integer { min = 1, max = 20 }
--
-- @param[opt] flags
-- @treturn int
function chance.basic.integer(flags)
    local min, max = -2^16, 2^16

    if flags then
        if flags["min"] then min = flags["min"] end
        if flags["max"] then max = flags["max"] end
    end

    return chance.core.random(min, max)
end

--- Returns a random natural number.
--
-- By default the function returns a number between zero and positive
-- inifinity.  But it accepts an optional table of flags which can
-- define inclusive "min" and "max" ranges for the result.  Minimum
-- values less than zero are rounded up to zero.
--
-- @see chance.basic.integer
--
-- @param[opt] flags
-- @treturn int
function chance.basic.natural(flags)
    if flags then
        if (flags["min"] == nil) or (flags["min"] and flags["min"] < 0) then
            flags["min"] = 0
        end
        return chance.basic.integer(flags)
    end
    return chance.basic.integer { min = 0 }
end

-- These groups are preset "pools" for chance.basic.character().
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
-- @usage anything = chance.basic.character()
-- @usage anything = chance.basic.character { group = "all" }
-- @usage vowel = chance.basic.character { pool = "aeiou" }
-- @usage capital = chance.basic.character { group = "upper" }
--
-- @param[opt] flags
-- @treturn string
function chance.basic.character(flags)
    local pool = character_groups["all"]

    if flags then
        if flags["pool"] then
            pool = flags["pool"]
        elseif flags["group"] then
            pool = character_groups[flags["group"]]
        end
    end

    local index = chance.core.random(pool:len())
    return pool:sub(index, index)
end

--- Returns a random string.
--
-- This function will return a string of random characters, with a
-- random length of five to twenty characters.  The optional flags
-- table can set "length" explicitly.  It also accepts a "group" flag
-- which determines what kind of characters appear in the string.
--
-- @see chance.basic.character
--
-- @usage chance.basic.string() == "c0Ab3le8"
-- @usage chance.basic.string { length = 3 } == "NIN"
-- @usage chance.basic.string { group = "digit" } = "8374933749"
--
-- @param[opt] flags
-- @treturn string
function chance.basic.string(flags)
    local length = chance.core.random(5, 20)
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
        result = result .. chance.basic.character { group = group }
        count = count + 1
    end

    return result
end


--- Text
--
-- These are functions for generating random text.
--
-- @section Text

chance.text = {}

--- Data used to build random syllables.
--
-- @see chance.text.syllable
-- @local
-- @field syllables
-- @table chance.core.dataSets
chance.core.set("syllables", {
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
-- @usage chance.text.syllable() == "peep"
-- @see chance.text.word
--
-- @treturn string
function chance.text.syllable()
    local initial = chance.helpers.pick(chance.core.dataSets["syllables"]["consonants"])
    local vowel = chance.helpers.pick(chance.core.dataSets["syllables"]["vowels"])
    local ending = chance.helpers.pick(chance.core.dataSets["syllables"]["consonants"])
    local syllable = initial .. vowel

    -- Fifty percent of the time we add an additional consonant sound
    -- to the end of the syllable.
    if chance.basic.bool() == true then
        syllable = syllable .. ending
    end

    return syllable
end

--- Returns a random word.
--
-- The word, by default, will contain one to three syllables.
-- However, the optional flag <code>syllables</code> can specify
-- exactly how many syllables to use in the word.  Note that
-- "syllable" in this context means anything which
-- @{chance.text.syllable} will return.
--
-- @usage chance.text.word() == "beepbop"
-- @usage chance.text.word { syllables = 4 } == "thadoobgerlu"
-- @see chance.text.syllable
--
-- @param[opt] flags
-- @treturn string
function chance.text.word(flags)
    local syllableCount = chance.core.random(1, 3)
    local word = ""

    if flags and flags["syllables"] then
        syllableCount = flags["syllables"]
    end

    if syllableCount < 1 then return word end

    while syllableCount > 0 do
        syllableCount = syllableCount - 1
        word = word .. chance.text.syllable()
    end

    return word
end

--- Generates a random sentence of words via @{chance.text.word}.
--
-- This function returns a sentence of random words, between twelve to
-- eighteen words by default.  The optional <code>words</code> flag
-- allows controling exactly how many words appear in the sentence.
-- The first word in the sentence will be capitalized and the sentence
-- will end with a period.
--
-- @usage chance.text.sentence { words = 3 } == "Hob the rag."
-- @see chance.text.word
--
-- @param[opt] flags
-- @treturn string
function chance.text.sentence(flags)
    local words
    local wordCount = chance.core.random(12, 18)

    if flags and flags["words"] then
        wordCount = flags["words"]
    end

    words = chance.misc.n(chance.text.word, wordCount)
    words[1] = string.gsub(words[1], "^%l", string.upper)
    table.insert(words, ".")

    return table.concat(words, " ")
end

--- Generates a random paragraph via @{chance.text.sentence}.
--
-- This function returns a paragraph of random sentences, created by
-- calling @{chance.text.sentence}.  By default the paragraph will
-- contain three to seven sentences.  However, the optional integer
-- flag <code>sentences</code> controls exactly how many sentences to
-- create for the paragraph.
--
-- @see chance.text.sentence
--
-- @param[opt] flags
-- @treturn string
function chance.text.paragraph(flags)
    local count = chance.core.random(3, 7)

    if flags and flags["sentences"] then
        count = flags["sentences"]
    end

    return makeStringFrom(chance.text.sentence, count)
end


--- Person
--
-- These are functions for generating random data about people.
--
-- @section Person

chance.person = {}

--- Generates a random United States Social Security Number.
--
-- This function generates a random United States Social Security
-- Number and returns it as a string, <code>AAA-GG-SSSS</code>, where
-- the digits represent the Area, Group, and Serial numbers,
-- respectively.  The function will not return all zeros for any part
-- of the number, nor will the Area ever be '666' or '900-999', per
-- the standards on Social Security Numbers.
--
-- @usage chance.person.ssn() == "343-74-0571"
--
-- @treturn string
function chance.person.ssn()
    local area, group, serial

    while true do
        area = chance.basic.string { length = 3, group = "digit" }
        if not area:match("000") and not area:match("9%d%d") then
            break
        end
    end

    while true do
        group = chance.basic.string { length = 2, group = "digit" }
        if not group:match("00") then
            break
        end
    end

    while true do
        serial = chance.basic.string { length = 4, group = "digit" }
        if not serial:match("0000") then
            break
        end
    end

    return string.format("%s-%s-%s", area, group, serial)
end

--- The possible genders returned by @{chance.person.gender}.
--
-- This is a table of strings which the @{chance.person.gender}
-- function will randomly choose from when called.  Developers can
-- modify the domain of @{chance.person.gender} by changing this table
-- to include or remove possible values as needed for their purposes.
-- The default values are based on common gender identities in modern
-- socities as opposed to gender based on medical qualification
-- (e.g. chromosones) or sexual orientation.
--
-- @see chance.person.gender
-- @local
-- @field genders
-- @table chance.core.dataSets
chance.core.set("genders", {
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
-- @usage chance.person.gender() == "Female"
-- @usage chance.person.gender { binary = true } == "Male"
--
-- @see chance.core.dataSets
--
-- @param[opt] flags
-- @treturn string
function chance.person.gender(flags)
    if flags and flags["binary"] == true then
        return chance.helpers.pick { "Male", "Female" }
    end
    return chance.core.fromSet("genders")
end

--- Possible words returned by @{chance.person.prefix}
--
-- @see chance.person.prefix
-- @local
-- @field prefixes
-- @table chance.core.dataSets
chance.core.set("prefixes", {
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
-- @usage chance.person.prefix() == "Mrs."
-- @usage chance.person.prefix { type = "long" } == "Doctor"
--
-- @param[opt] flags
-- @treturn string
function chance.person.prefix(flags)
    local prefixType = "short"
    if flags and flags["type"] then
        prefixType = string.lower(flags["type"])
    end
    return chance.helpers.pick(chance.core.dataSets["prefixes"][prefixType])
end

--- Possible words returned by @{chance.person.suffix}
--
-- @see chance.person.suffix
-- @local
-- @field suffixes
-- @table chance.core.dataSets
chance.core.set("suffixes", {
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
-- @usage chance.person.suffix() == "Sr."
-- @usage chance.person.suffix { type = "long" } == "Senior"
--
-- @param[opt] flags
-- @treturn string
function chance.person.suffix(flags)
    local suffixType = "short"
    if flags and flags["type"] then
        suffixType = string.lower(flags["type"])
    end
    return chance.helpers.pick(chance.core.dataSets["suffixes"][suffixType])
end

--- Ranges for various types of ages.
--
-- @see chance.person.age
-- @local
-- @field ages
-- @table chance.core.dataSets
chance.core.set("ages", {
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
-- one can use @{chance.core.set} and @{chance.core.appendSet} to
-- redefine the ranges for types and/or add new types.
--
-- @usage chance.person.age() == 33
-- @usage chance.person.age { type = "teen" } == 17
-- @usage chance.person.age { type = "adult" } == 40
--
-- @param[opt] flags
-- @treturn int
function chance.person.age(flags)
    if flags and flags["type"] then
        local group = chance.core.dataSets["ages"][flags["type"]]
        return chance.core.random(group[1], group[2])
    end
    return chance.core.random(1, 120)
end


--- Time
--
-- These are functions for generating random times.
--
-- @section Time

chance.time = {}

--- Returns a random hour.
--
-- By default this will return an hour in the range of one to twelve.
-- However, if the optional flag <code>twentyfour</code> is true then
-- the result will be in the range of one to twenty-four.
--
-- @usage chance.time.hour() == 3
-- @usage chance.time.hour { twentyfour = true } == 15
--
-- @param[opt] flags
-- @treturn number
function chance.time.hour(flags)
    if flags and flags["twentyfour"] == true then
        return chance.core.random(1, 24)
    else
        return chance.core.random(1, 12)
    end
end

--- Returns a random minute.
--
-- This will return a number in the range of zero to fifty-nine.
--
-- @treturn number
function chance.time.minute()
    return chance.core.random(0, 59)
end

--- Returns a random second.
--
-- This will return a number in the range of zero to fifty-nine.
--
-- @treturn number
function chance.time.second()
    return chance.core.random(0, 59)
end

--- Returns a random millisecond.
--
-- This returns a number in the range of zero to nine-hundred ninety
-- nine.
--
-- @treturn number
function chance.time.millisecond()
    return chance.core.random(0, 999)
end

--- Returns a random year.
--
-- By default this function returns a number representing a year in
-- the range of the current year and a century later.  For example,
-- calling <code>chance.time.year()</code> in the year 2015 will
-- return a number between 2015 and 2115.
--
-- The function accepts an optional table of flags which can have
-- <code>min</code> and <code>max</code> properties to restrict the
-- range of the output.  If only <code>min</code> is provided then the
-- maximum range is one century ahead of the minimum, for example
-- <code>chance.time.year { min = 1750 }</code> returns a year between
-- 1750 and 1850.  If only <code>max</code> is provided then the
-- minimum is the current year.
--
-- @usage chance.time.year() == 2074
-- @usage chance.time.year { min = 1800 } == 1884
-- @usage chance.time.year { max = 2300 } == 2203
-- @usage chance.time.year { min = 1990, max = 2000 } == 1995
--
-- @param[opt] flags
-- @treturn number
function chance.time.year(flags)
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

    return chance.core.random(minimum, maximum)
end

--- Names of months.
--
-- @see chance.time.month
-- @local
-- @field months
-- @table chance.core.dataSets
chance.core.set("months", {
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
function chance.time.month()
    return chance.core.fromSet("months")
end

--- Names of days of the week.
--
-- @see chance.time.day
-- @local
-- @field days
-- @table chance.core.dataSets
chance.core.set("days", {
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
-- @usage chance.time.day() == "Monday"
-- @usage chance.time.day { weekends = true } == "Sunday"
-- @usage chance.time.day { weekends = false } == "Thursday"
--
-- @param[opt] flags
-- @treturn string
function chance.time.day(flags)
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
        days = makeShallowCopy(chance.core.dataSets["days"][category])
    elseif category == "all" then
        for _,set in pairs(chance.core.dataSets["days"]) do
            for _,day in ipairs(set) do
                table.insert(days, day)
            end
        end
    end

    return chance.helpers.pick(days)
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
function chance.time.timestamp()
    return chance.core.random(0, os.time())
end

--- Returns 'am' or 'pm' for use with times.
--
-- @treturn string <code>"am"</code> or <code>"pm"</code>
function chance.time.ampm()
    local probability = chance.core.random()

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

chance.web = {}

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
-- @usage chance.web.color() == "#a034cc"
-- @usage chance.web.color { format = "shorthex" } == "#eeb"
-- @usage chance.web.color { format = "rgb" } == "rgb(120, 80, 255)"
-- @usage chance.web.color { greyscale = true } == "#3c3c3c"
--
-- @param[opt] flags
-- @treturn string
function chance.web.color(flags)
    local red, green, blue = unpack(chance.misc.n(chance.basic.string, 3, { length = 2, group = "hex" }))

    if flags then
        if flags["format"] == "shorthex" then
            red, green, blue = unpack(chance.misc.n(chance.basic.string, 3, { length = 1, group = "hex" }))
        elseif flags["format"] == "rgb" then
            red, green, blue = unpack(chance.misc.n(chance.basic.natural, 3, { min = 0, max = 255 }))
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
-- @usage chance.web.ip() == "132.89.0.200"
-- @usage chance.web.ip { class = "B" } == "190.1.24.30"
-- @usage chance.web.ip { octets = { 192, 128 }} == "192.128.0.1"
--
-- @see chance.web.ipv6
--
-- @param[opt] flags
-- @treturn string
function chance.web.ip(flags)
    local octets = chance.misc.n(chance.basic.natural, 4, { max = 255 })
    local rangesForClass = {
        ["A"] = {0, 127},
        ["B"] = {128, 191},
        ["C"] = {192, 223},
    }

    if flags then
        if flags["class"] then
            local range = rangesForClass[string.upper(flags["class"])]
            octets[1] = chance.core.random(range[1], range[2])
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
-- @see chance.web.ip
--
-- @treturn string
function chance.web.ipv6()
    local octet = function ()
        return chance.basic.string { length = 4, group = "hex" }
    end
    return makeStringFrom(octet, 8, ":")
end

--- Top-Level Domains
--
-- @see chance.web.tld
-- @local
-- @field tlds
-- @table chance.core.dataSets
chance.core.set("tlds", {
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
-- @usage chance.web.tld() == "net"
--
-- @treturn string
function chance.web.tld()
    return chance.core.fromSet("tlds")
end

--- Generate a random domain.
--
-- This function returns a random web domain.  By default the domain
-- name contains one to three words and a random top-level domain.
-- The optional flag <code>words</code> controls exactly how many
-- words appear in the domain, and the flag <code>tld</code> will
-- ensure the result uses that specific top-level domain.
--
-- @usage chance.web.domain() == "paroo.net"
-- @usage chance.web.domain { words = 1 } == "fee.gov"
-- @usage chance.web.domain { tld = "co.bh" } == "havashi.co.bh"
--
-- @see chance.text.word
-- @see chance.web.tld
--
-- @param[opt] flags
-- @treturn string
function chance.web.domain(flags)
    local wordCount = chance.core.random(1, 3)
    local tld = chance.web.tld()

    if flags then
        if flags["words"] then
            wordCount = flags["words"]
        end
        if flags["tld"] then
            tld = flags["tld"]
        end
    end

    return makeStringFrom(chance.text.word, wordCount) .. "." .. tld
end

--- Returns a random email address.
--
-- This function will return an email address consisting of random
-- words, belonging to a random domain.  The optional flag
-- <code>domain</code> can specify the exact domain to use.
--
-- @usage chance.web.email() == "foo@boohoo.edu"
-- @usage chance.web.email { domain = "example.com" } == "lepiwoa@example.com"
--
-- @see chance.text.word
-- @see chance.web.domain
--
-- @param[opt] flags
-- @treturn string
function chance.web.email(flags)
    local name = chance.text.word()
    local domain = chance.web.domain()

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
-- @usage chance.web.hashtag() == "#namarob"
-- @see chance.web.twitter
--
-- @treturn string
function chance.web.hashtag()
    return "#" .. makeStringFrom(chance.text.word, {1, 3})
end

--- Generates a random Twitter handle.
--
-- This function returns a string representing a random Twitter
-- account name.  The string will begin with '@' followed by one to
-- five words.
--
-- @usage chance.web.twitter() == "@meepboat"
-- @see chance.web.hashtag
--
-- @treturn string
function chance.web.twitter()
    return "@" .. makeStringFrom(chance.text.word, {1, 5})
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
-- @usage chance.web.uri() == "http://foobar.net/baz"
-- @usage chance.web.uri { domain = "example.com" } == "http://example.com/wee"
-- @usage chance.web.uri { path = "foo/bar" } == "http://narofu.edu/foo/bar"
-- @usage chance.web.uri { extensions = { "png", "gif" }} == "http://benhoo.gov/dao.png"
-- @usage chance.web.uri { protocol = "ftp" } == "ftp://fufoo.net/veto"
--
-- @see chance.web.domain
--
-- @param[opt] flags
-- @treturn string
function chance.web.uri(flags)
    local protocol = "http"
    local domain = chance.web.domain()
    local path = makeStringFrom(chance.text.word, {1, 2})
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
        uri = uri .. chance.helpers.pick(extensions)
    end

    return uri
end

--- Generates a random URL.
--
-- This function is an alias for @{chance.web.uri}.
--
-- @param[opt] flags
-- @treturn string
-- @function chance.web.url
chance.web.url = chance.web.uri


--- Poker
--
-- These are functions for generating random data related to the
-- card game Poker and its variants.
--
-- @section Poker

chance.poker = {}

--- Ranks and Suits for Cards
--
-- @local
-- @field cards
-- @table chance.core.dataSets
chance.core.set("cards", {
        ["ranks"] = {
            2, 3, 4, 5, 6, 7, 8, 9, 10,
            "Jack", "Queen", "King", "Ace", "Joker",
        },
        ["suits"] = {
            "Heart", "Diamond", "Club", "Spade",
        }
})

--- Returns a random Poker card.
--
-- The functions returns a table representing a random Poker card.
-- The table will have two keys:
--
-- <ol>
-- <li><code>rank</code>: A number in the range of [2, 10], or the
-- strings "Jack", "Queen", "King", "Ace", and "Joker".</li>
-- <li><code>suit</code>: A string with the possible values of
-- "Spade", "Heart", "Club", and "Diamond".</li>
-- </ol>
--
-- The function accepts an optional table of flags:
--
-- If the <code>joker</code> flag has a boolean false value then the
-- function will never return the Joker.
--
-- The <code>rank</code> and <code>suit</code> flags accept values to
-- use explicitly for the rank and suit of the generated card.
--
-- @usage chance.poker.card() == { rank = 4, suit = "Club" }
-- @usage chance.poker.card { rank = "Jack" } == { rank = "Jack", suit = "Heart" }
-- @usage chance.poker.card { suit = "Spade" } == { rank = 10, suit = "Spade" }
-- @usage chance.poker.card { joker = false } == { rank = 5, suit = "Diamond" }
--
-- @param[opt] flags
-- @treturn table card
function chance.poker.card(flags)
    local rank = chance.helpers.pick(chance.core.dataSets["cards"]["ranks"])
    local suit = chance.helpers.pick(chance.core.dataSets["cards"]["suits"])

    if flags then
        if flags["rank"] then rank = flags["rank"] end
        if flags["suit"] then suit = flags["suit"] end
        if flags["joker"] ~= nil and flags["joker"] == false then
            repeat
                rank = chance.helpers.pick(chance.core.dataSets["cards"]["ranks"])
            until rank ~= "Joker"
        end
    end

    return { rank = rank, suit = suit }
end

--- Returns a deck of Poker cards.
--
-- This function returns a table representing a deck of Poker cards.
-- By default the deck contains 52 cards, i.e. it does not include the
-- Joker.  However, if the optional <code>joker</code> flag is present
-- and has a boolean true value then the deck will include the Joker,
-- for a total of 53 cards.
--
-- @see chance.poker.card
--
-- @usage local deck = chance.poker.deck(); #deck == 52
-- @usage local deck = chance.poker.deck { joker = true }; #deck == 53
--
-- @param[opt] flags
-- @treturn table deck
function chance.poker.deck(flags)
    local deck = {}

    for _,suit in ipairs(chance.core.dataSets["cards"]["suits"]) do
        for _,rank in ipairs(chance.core.dataSets["cards"]["ranks"]) do
            if rank ~= "Joker" then
                table.insert(deck, { rank = rank, suit = suit })
            end
        end
    end

    if flags and flags["joker"] == true then
        table.insert(deck, { rank = "Joker", suit = "Joker" })
    end

    return deck
end

--- Returns a hand of Poker cards.
--
-- By default this function returns a table with five elements, cards
-- generated by calling the @{chance.poker.card} function.  The hand
-- will contain unique cards.  And the function will contain cards
-- from the standard deck created by @{chance.poker.deck}.
--
-- If given the optional flag <code>cards</code> then the function
-- will return a hand containing that number of cards.  If given the
-- optional flag <code>deck</code> then it will select cards from that
-- deck, which must be a table of cards, like the kind that
-- @{chance.poker.deck} will create.
--
-- @see chance.poker.card
-- @see chance.poker.deck
--
-- @param[opt] flags
-- @treturn table hand
function chance.poker.hand(flags)
    local count = 5
    local deck = chance.poker.deck()

    if flags then
        if flags["cards"] then count = flags["cards"] end
        if flags["deck"] then deck = flags["deck"] end
    end

    if count >= #deck then
        return deck
    else
        return chance.helpers.pick_unique(deck, count)
    end
end


--- Miscellaneous
--
-- These are functions for generating data which does not easily fall
-- under any other category.
--
-- @section Miscellaneous

chance.misc = {}

--- Returns a normally-distributed random value.
--
-- By default the function returns a value with a mean of zero and a
-- standard deviation of one.  However, the optional flags
-- <code>mean</code> and <code>deviation</code> can provide different
-- values to use for each.
--
-- @usage chance.misc.normal() == 0.2938473
-- @usage chance.misc.normal { mean = 100 } == 99.172493
-- @usage chance.misc.normal { mean = 100, deviation = 15 } == 85.83741
--
-- @param[opt] flags
-- @treturn number
function chance.misc.normal(flags)
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
        u = chance.core.random() * 2 - 1
        v = chance.core.random() * 2 - 1
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
-- the same length then the function returns
-- <code>nil</code>.</strong>
--
-- @usage chance.misc.weighted({"a", "b"}, {100, 1})
-- -- This will return "a" one-hundred times more often than
-- -- it will return "b".
--
-- @tparam table values
-- @tparam table weights
-- @return A element from the <code>values</code> array
function chance.misc.weighted(values, weights)
    if #values ~= #weights then return nil end

    local sum = 0
    for _,weight in ipairs(weights) do
        sum = sum + weight
    end

    local chosenIndex = chance.basic.natural { min = 1, max = sum }
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
-- @usage switches = chance.misc.n(chance.basic.bool, 3)
-- @usage numbers = chance.misc.n(chance.basic.natural, 10, { max = 100 })
--
-- @param generator A function that returns random data.
-- @param count The number of times to call the generator.
-- @param[opt] ... Additional arguments passed to the generator.
-- @treturn table
function chance.misc.n(generator, count, ...)
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
-- This function is similar to @{chance.misc.n} in that it accepts a
-- generator function, often another <code>chance</code> function, and
-- a number of items to generate.  The function will return an array
-- containing that many items, randomly generated by the given
-- function.  However, unlike @{chance.misc.n}, the items in the array
-- are guaranteed to be unique.
--
-- Any additional arguments will be given to the generator function on
-- each invocation.
--
-- @usage chance.misc.unique(chance.time.month, 3) == { "May", "February", "April" }
-- @usage chance.misc.unique(chance.basic.character, 2, { pool = "aeiou" }) == { "e", "u" }
--
-- @param generator A function that returns random data.
-- @param count The number of times to call the generator.
-- @param[opt] ... Additional arguments passed to the generator.
-- @treturn table
function chance.misc.unique(generator, count, ...)
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
-- @usage chance.misc.hash() == "9f3cbf2466d865d82310b9b1e785401556daedce"
-- @usage chance.misc.hash { digits = 8 } == "5d82310b"
--
-- @param[opt] flags
-- @treturn string
function chance.misc.hash(flags)
    local digits = 40

    if flags and flags["digits"] then
        digits = flags["digits"]
    end

    return chance.basic.string { group = "hex", length = digits }
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
-- @usage chance.misc.rpg("1d8") == {4}
-- @usage chance.misc.rpg("3d20") == {10, 4, 17}
--
-- @param notation
-- @treturn table The values of each die roll.
function chance.misc.rpg(notation)
    local _,middle = notation:lower():find("d")
    local rolls = tonumber(notation:sub(1, middle - 1))
    local die = tonumber(notation:sub(middle + 1))
    local results = {}

    while rolls > 0 do
        table.insert(results, chance.core.random(1, die))
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
-- ...we end up with the function chance.misc.d10(), which will return
-- the result of rolling a ten-sided die once.
--
-- @local
local function createDieRollFunction(die)
    chance.misc["d" .. die] = function ()
        local roll = chance.misc.rpg("1d" .. die)
        return roll[1]
    end
end

--- Roll a 4-sided die.
--
-- @function chance.misc.d4
-- @treturn number
createDieRollFunction("4")

--- Roll a 6-sided die.
--
-- @function chance.misc.d6
-- @treturn number
createDieRollFunction("6")

--- Roll an 8-sided die.
--
-- @function chance.misc.d8
-- @treturn number

createDieRollFunction("8")
--- Roll a 10-sided die.
--
-- @function chance.misc.d10
-- @treturn number

createDieRollFunction("10")
--- Roll a 12-sided die.
--
-- @function chance.misc.d12
-- @treturn number

createDieRollFunction("12")
--- Roll a 20-sided die.
--
-- @function chance.misc.d20
-- @treturn number
createDieRollFunction("20")

--- Roll a 100-sided die.
--
-- @function chance.misc.d100
-- @treturn number
createDieRollFunction("100")


--- Helpers
--
-- These are functions that help select random data from existing
-- sources or define new random content generation functions.
--
-- @section Helpers

chance.helpers = {}

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
function chance.helpers.pick(array, count)
    local size = #array

    if count ~= nil and count > 0 then
        local results = {}
        while count > 0 do
            table.insert(results, array[chance.core.random(1, size)])
            count = count - 1
        end
        return results
    end

    return array[chance.core.random(1, size)]
end

--- Pick a random collection of unique elements from an array.
--
-- This function is like @{chance.helpers.pick} except that the
-- <code>count</code> parameter is mandatory and the array that the
-- function returns will not have any duplicate elements.
--
-- @see chance.helpers.pick
--
-- @tparam table array
-- @tparam number count
-- @treturn table
function chance.helpers.pick_unique(array, count)
    local data = makeShallowCopy(array)
    local choices = {}

    while count > 0 do
        local index = chance.core.random(1, #data)
        table.insert(choices, data[index])
        table.remove(data, index)
        count = count - 1
    end

    return choices
end

--- Randomly shuffle the contents of an array.
--
-- This function takes an array, i.e. a table with only numeric
-- indices, and returns a new table of the same size and with those
-- same elements except in a random order.  Naturally there is the
-- possibility that the shuffled array will be randomly,
-- coincidentally equal to the original.
--
-- @usage chance.helpers.shuffle {"foo", "bar", "baz"} == {"bar", "foo", "baz"}
--
-- @param array
-- @treturn table
function chance.helpers.shuffle(array)
    local original = makeShallowCopy(array)
    local shuffled = {}
    local count = #original

    while count > 0 do
        local position = chance.core.random(1, count)
        table.insert(shuffled, original[position])
        table.remove(original, position)
        count = count - 1
    end

    return shuffled
end


-- Return the module.  This should always be the final line of code.
return chance

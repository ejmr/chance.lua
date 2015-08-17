--[[--

Chance: A Library for Generating Random Data

@module chance
@author Eric James Michael Ritz
@copyright 2015 Plutono Inc
@license GNU General Public License
@release <a href="https://github.com/ejmr/chance.lua">Project Home</a>

--]]--

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
        ["MINOR"] = 1,
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
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
        "Sunday",
})

--- Returns a random day of the week.
--
-- By default this function will return the name of a day of the week,
-- chosen from the <code>days</code> data set.  The function accepts
-- an optional table of flags which control the possible days it
-- returns.  If the flags <code>weekdays</code> or
-- <code>weekends</code> are false then the function will not return
-- those types of days.
--
-- @usage chance.day() == "Monday"
-- @usage chance.day { weekdays = false } == "Sunday"
-- @usage chance.day { weekends = false } == "Thursday"
--
-- @param[opt] flags
-- @treturn string
function chance.day(flags)
    local days = makeShallowCopy(chance.dataSets["days"])

    -- This logic takes advantage of the specific order of the `days`
    -- table above.
    if flags then
        if flags["weekdays"] == false then
            for i = 1, 5 do
                table.remove(days, i)
            end
        elseif flags["weekends"] == false then
            table.remove(days)
            table.remove(days)
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

--- Miscellaneous
--
-- These are functions for generating data which does not easily fall
-- under any other category.
--
-- @section Miscellaneous

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

--- Create an array of die rolls using Dungeons and Dragons notation.
--
-- This function returns an array of random numbers simulating the
-- results of rolling dice of the kind found in most table-top RPGs
-- such as Dungeons and Dragons.  The argument to the function must be
-- a string of the form <code>#d#</code> where each <code>#</code> is
-- a number; the first represents the number of rolls to make, and the
-- second represents the number of sides on the die, e.g. <code>3d6</code>
-- returns an array with three numbers, each being the result of rolling
-- a six-sided die.
--
-- @usage chance.rpg("1d8") == {4}
-- @usage chance.rpg("3d20") == {10, 4, 17}
--
-- @param notation
-- @treturn table The values of each die roll.
function chance.rpg(notation)
    local _,middle = notation:find("d")
    local rolls = tonumber(notation:sub(1, middle - 1))
    local die = tonumber(notation:sub(middle + 1))
    local results = {}

    while rolls > 0 do
        table.insert(results, chance.random(1, die))
        rolls = rolls - 1
    end

    return results
end

-- This utility function accepts a die as a string, i.e. the number of
-- sides on the die, and creates a public API function which returns
-- one number by rolling that die.  For example, after calling...
--
--     createDieRollFunction("10")
--
-- ...we end up with the function chance.d10(), which will return the
-- result of rolling a ten-sided die once.
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

return chance

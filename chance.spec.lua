local chance = require("chance")
local assert = require("luassert")
local say    = require("say")

say:set_namespace("en")

-- This assertion requires one argument: an array.  The assertion is
-- true if the array contains unique values.  For example, the
-- assertion is true for `{ 1, 2, 3 }` but false for `{ 1, 1, 2 }`.
-- The assertion uses the simple `==` operator for testing equality,
-- meaning the assertion will not ensure elements are unique for any
-- nested arrays.
local function unique_array(state, arguments)
    local array = arguments[1]

    for _,x in ipairs(array) do
        local matches = 0

        for _,y in ipairs(array) do
            if x == y then
                matches = matches + 1
            end
        end

        if matches ~= 1 then
            return false
        end
    end

    return true
end

say:set("assertion.unique_array.positive", "Expected array to have all unique values:\n%s")
say:set("assertion.unique_array.negative", "Expected array to have some duplicate values:\n%s")
assert:register("assertion", "unique_array", unique_array,
                "assertion.unique_array.positive",
                "assertion.unique_array.negative")

-- This assertion requires three arguments, which all must be numbers.
-- The assertion is true if the first number is within the range of
-- the second and third numbers, the minimum and maximum of the range,
-- respectively.  By default the test is inclusive.  However, an
-- optional fourth argument can be a table with the key-value pair
-- "exclusiveMax = true".  If present then the test against the
-- maximum value will be exclusive.
local function within_range(state, arguments)
    local value = arguments[1]
    local minimum = arguments[2]
    local maximum = arguments[3]

    if arguments[4] and arguments[4]["exclusiveMax"] == true then
        return value >= minimum and value < maximum
    else
        return value >= minimum and value <= maximum
    end
end

say:set("assertion.within_range.positive", "Expected value %s to be within range:\n%s and %s")
say:set("assertion.within_range.negative", "Expected value %s to not be within range:\n%s and %s")
assert:register("assertion", "within_range", within_range,
                "assertion.within_range.positive",
                "assertion.within_range.negative")

-- This assertion requires two arguments.  The first argument can be
-- any type of value.  The second argument must be a table.  The
-- assertion tests whether or not that value exists in the table.  If
-- we think of the table as an array then this assertion checks to see
-- if the element exists in that array.
local function in_array(state, arguments)
    local element = arguments[1]
    local array = arguments[2]

    for _,value in ipairs(array) do
        if value == element then return true end
    end

    return false
end

say:set("assertion.in_array.positive", "Expected value %s to be a value in array:\n%s")
say:set("assertion.in_array.negative", "Expected value %s to not be a value in array:\n%s")
assert:register("assertion", "in_array", in_array,
                "assertion.in_array.positive",
                "assertion.in_array.negative")



describe("The Core API", function ()

    it("Accepts a number to seed the RNG", function ()
        assert.has_no.errors(function () chance.seed(os.time()) end)
        assert.has.errors(function () chance.seed("foo") end)
    end)

    describe("chance.random()", function ()

        before_each(function () chance.seed(os.time()) end)

        it("Returns a number in the range [0, 1) given no arguments", function ()
            assert.is.within_range(chance.random(), 0, 1, { exclusiveMax = true })
        end)

        it("Returns a number in the range [1, m] given one argument", function ()
            assert.is.within_range(chance.random(5), 1, 5)
        end)

        it("Returns a number in the range [m, n] given two arguments", function ()
            assert.is.within_range(chance.random(5, 10), 5, 10)
        end)

    end)

    describe("Data sets, i.e. the chance.dataSets table", function ()
        local setName, setData

        setup(function ()
            setName = "testNames"
            setData = { "Eric", "Jeff", "Mira", "Ben" }
        end)

        it("Provides chance.set() to create data sets and chance.fromSet() to get data", function ()
            chance.set(setName, setData)
            assert.is.truthy(chance.dataSets[setName])
            assert.is.equal(chance.dataSets[setName], setData)
            assert.is.in_array(chance.fromSet(setName), setData)
        end)

        it("Can create a data set by giving a function to chance.set()", function ()
            local generator = function ()
                return chance.pick(setData)
            end
            chance.set(setName, generator)
            assert.is.in_array(chance.fromSet(setName), setData)
        end)

        it("Can add data to an existing set via chance.appendSet()", function ()
            chance.set(setName, setData)
            local oldSize = #setData
            assert.is.equal(chance.dataSets[setName], setData)

            chance.appendSet(setName, { "Lobby" })
            local newSize = #setData
            assert.is.equal(#chance.dataSets[setName], newSize)
        end)

        it("Can overwrite an existing data set via chance.set()", function ()
            chance.set(setName, setData)
            assert.is.in_array(chance.fromSet(setName), setData)
            chance.set(setName, { "Foo" })
            assert.is.in_array(chance.fromSet(setName), { "Foo" })
            assert.is.not_in_array(chance.fromSet(setName), setData)
        end)
    end)
end)

describe("The Basic API", function ()

    before_each(function () chance.seed(os.time()) end)

    describe("chance.bool()", function ()
        it("Can return true with a given probability", function ()
            assert.equals(true, chance.bool { probability = 100 })
            assert.equals(false, chance.bool { probability = 0 })
        end)
    end)

    describe("chance.float()", function ()
        it("Returns a number in the range [0,1)", function ()
            assert.is.within_range(chance.float(), 0, 1, { exclusiveMax = true })
        end)
    end)

    describe("chance.integer()", function ()
        it("Returns a number in the range (-INF, INF) given no arguments", function ()
            assert.is.within_range(chance.integer(), -math.huge, math.huge)
        end)

        it("Allows explicitly restricting the minimum and maximum ranges", function ()
            assert.is.within_range(chance.integer { min = 0 }, 0, math.huge)
            assert.is.within_range(chance.integer { max = 1 }, -math.huge, 1)
            assert.is.within_range(chance.integer { min = 1, max = 3 }, 1, 3)
        end)
    end)

    describe("chance.natural()", function ()
        it("Returns a number in the range [0, INF) given no arguments", function ()
            assert.is.within_range(chance.natural(), 0, math.huge)
        end)

        it("Allows explicitly restricting the minimum and maximum ranges", function ()
            assert.is.within_range(chance.natural { min = 1 }, 1, math.huge)
            assert.is.within_range(chance.natural { max = 1 }, 0, 1)
            assert.is.within_range(chance.natural { min = 1, max = 3 }, 1, 3)
        end)

        it("Will not produce negative numbers", function ()
            assert.equals(0, chance.natural { min = -10, max = 0 })
        end)
    end)

    describe("chance.character()", function ()
        it("Can return a random character from a given pool", function ()
            assert.equals("a", chance.character { pool = "a" })
        end)

        it("Gives explicit pools precedence over predefined groups", function ()
            assert.equals("a", chance.character { pool = "a", group = "digit" })
        end)
    end)

    describe("chance.string()", function ()
        it("Can generate strings of a fixed length", function ()
            assert.equals(5, string.len(chance.string { length = 5 }))
        end)
    end)

end)

describe("The Text API", function ()

    before_each(function () chance.seed(os.time()) end)

    describe("chance.syllable()", function ()
        it("Returns syllables of two to six characters in length", function ()
            assert.is.within_range(string.len(chance.syllable()), 2, 6)
        end)
    end)

    describe("chance.word()", function ()
        it("Returns a word of one to three syllables by default", function ()
            assert.is.within_range(string.len(chance.word()), 2, 18)
        end)

        it("Can create words with a specific number of syllables", function ()
            local word = chance.word { syllables = 10 }
            assert.is.within_range(string.len(word), 20, 60)
        end)
    end)

    describe("chance.sentence()", function ()
        local split_string

        setup(function ()
            split_string = function (s)
                local words = {}
                for w in string.gmatch(s, "%A+") do
                    table.insert(words, w)
                end
                return words
            end
        end)

        it("Returns a sentence between twelve and eighteen words by default", function ()
            local words = split_string(chance.sentence())
            assert.is.within_range(#words, 12, 18)
        end)

        it("Can return a sentence with a specific number of words", function ()
            local count = 5
            local words = split_string(chance.sentence { words = count })
            assert.is.equal(#words, count)
        end)
    end)

    describe("chance.paragraph()", function ()
        local split_string

        setup(function ()
            split_string = function (s)
                local sentences = {}
                for n in string.gmatch(s, "[%a%s]+%.") do
                    table.insert(sentences, n)
                end
                return sentences
            end
        end)

        it("Returns a paragraph of three to seven sentences by default", function ()
            local sentences = split_string(chance.paragraph())
            assert.is.within_range(#sentences, 3, 7)
        end)

        it("Can generate a specific number of sentences", function ()
            local count = 10
            local sentences = split_string(chance.paragraph { sentences = count })
            assert.is.equal(#sentences, count)
        end)
    end)

end)

describe("The Person API", function ()

    before_each(function () chance.seed(os.time()) end)

    describe("chance.prefix()", function ()
        it("Returns a short prefix by default", function ()
            assert.is.in_array(chance.prefix(), chance.dataSets["prefixes"]["short"])
        end)

        it("Can return a long prefix", function ()
            assert.is.in_array(chance.prefix { type = "long" }, chance.dataSets["prefixes"]["long"])
        end)
    end)

    describe("chance.suffix()", function ()
        it("Returns a short suffix by default", function ()
            assert.is.in_array(chance.suffix(), chance.dataSets["suffixes"]["short"])
        end)

        it("Can return a long suffix", function ()
            assert.is.in_array(chance.suffix { type = "long" }, chance.dataSets["suffixes"]["long"])
        end)
    end)

    describe("chance.gender()", function ()
        it("Returns a value from the 'genders' data set by default", function ()
            assert.in_array(chance.gender(), chance.dataSets["genders"])
        end)

        it("Can be restricted to binary Male or Female", function ()
            assert.in_array(chance.gender { binary = true }, { "Male", "Female" })
        end)

        it("Supports customizing its output domain via data sets", function ()
            local genders = { "M", "F", "N" }
            chance.set("genders", genders)
            assert.in_array(chance.gender(), chance.dataSets["genders"])
        end)
    end)

    describe("chance.age()", function ()
        it("Returns an age in the range [1, 120] by default", function ()
            assert.is.within_range(chance.age(), 1, 120)
        end)

        it("Has predefined age types", function ()
            assert.is.within_range(chance.age { type = "child" }, 1, 12)
            assert.is.within_range(chance.age { type = "teen" }, 13, 19)
            assert.is.within_range(chance.age { type = "adult" }, 18, 65)
            assert.is.within_range(chance.age { type = "senior" }, 65, 100)
        end)
    end)

end)

describe("The Time API", function ()

    before_each(function () chance.seed(os.time()) end)

    it("Can generate random hours", function ()
        assert.is.within_range(chance.hour(), 1, 12)
        assert.is.within_range(chance.hour { twentyfour = true }, 1, 24)
    end)

    it("Can generate random minutes", function ()
        assert.is.within_range(chance.minute(), 0, 59)
    end)

    it("Can generate random seconds", function ()
        assert.is.within_range(chance.second(), 0, 59)
    end)

    it("Can generate random milliseconds", function ()
        assert.is.within_range(chance.millisecond(), 0, 999)
    end)

    it("Can randomly produce 'am' or 'pm' for times", function ()
        local meridiem = chance.ampm()
        assert.is_true(meridiem == "am" or meridiem == "pm")
    end)

    describe("chance.year()", function ()
        it("By default returns a year between the current and a century later", function ()
            local random_year = chance.year()
            local current_date = os.date("*t")
            assert.is.within_range(random_year, current_date["year"], current_date["year"] + 100)
        end)

        it("Can be restricted to a minimum and/or maximum range", function ()
            local current_date = os.date("*t")
            assert.is.within_range(chance.year { min = 1700 }, 1700, 1800)
            assert.is.within_range(chance.year { max = 2200 }, current_date["year"], 2200)
            assert.is.within_range(chance.year { min = 1984, max = 2002 }, 1984, 2002)
        end)
    end)

    it("Can randomly generate a month by name", function ()
        assert.in_array(chance.month(), chance.dataSets["months"])
    end)

    it("Can generate a random Unix timestamp", function ()
        assert.is.within_range(chance.timestamp(), 0, os.time())
    end)

    describe("chance.day()", function ()
        local alldays, weekdays, weekends

        setup(function ()
            alldays = {
                "Monday",
                "Tuesday",
                "Wednesday",
                "Thursday",
                "Friday",
                "Saturday",
                "Sunday"
            }
            weekdays = {
                "Monday",
                "Tuesday",
                "Wednesday",
                "Thursday",
                "Friday"
            }
            weekends = {
                "Saturday",
                "Sunday"
            }
        end)

        it("Can return any day of the week", function ()
            assert.in_array(chance.day(), alldays)
        end)

        it("Can return only weekdays", function ()
            assert.in_array(chance.day { weekdays = true }, weekdays)
            assert.in_array(chance.day { weekends = false }, weekdays)
        end)

        it("Can return only weekends", function ()
            assert.in_array(chance.day { weekends = true }, weekends)
            assert.in_array(chance.day { weekdays = false }, weekends)
        end)
    end)

end)

describe("The Web API", function ()

    before_each(function () chance.seed(os.time()) end)

    describe("chance.tld()", function ()
        it("Returns a random top-level domain from the 'tlds' data set", function ()
            assert.is.in_array(chance.tld(), chance.dataSets["tlds"])
        end)
    end)

    describe("chance.domain()", function ()
        it("Returns a domain of random words and a random TLD by default", function ()
            local domain = chance.domain()
            for name,tld in string.gmatch(domain, "(%w+)%.([%w%.]+)") do
                -- The length of one to three words.
                assert.is.within_range(string.len(name), 2, 54)
                assert.is.in_array(tld, chance.dataSets["tlds"])
            end
        end)

        it("Can use an explicit top-level domain", function ()
            local domain = chance.domain { tld = "name" }
            for tld in string.gmatch(domain, "%w+%.(%w+)") do
                assert.is.equal(tld, "name")
            end
        end)
    end)

    describe("chance.email()", function ()
        it("Returns a random name with a random domain by default", function ()
            local email = chance.email()
            for name,domain,tld in string.gmatch(email, "(%w+)@(%w+)%.(%w+)") do
                assert.is.in_array(tld, chance.dataSets["tlds"])
            end
        end)

        it("Can create an email address for an explicit domain", function ()
            local email = chance.email { domain = "example.com" }
            for name,domain in string.gmatch(email, "(%w+)@([%w%.]+)") do
                assert.is.equal(domain, "example.com")
            end
        end)
    end)

    describe("chance.hashtag()", function ()
        it("Returns a Twitter hashtag built of random words", function ()
            assert.is.truthy(string.match(chance.hashtag(), "^#%w+$"))
        end)
    end)

end)

describe("The Helper API", function ()

    before_each(function () chance.seed(os.time()) end)

    describe("chance.pick()", function ()
        it("Randomly selects an element from a table", function ()
            local choice = chance.pick({"foo", "bar", "baz"})
            assert.is_true(choice == "foo" or choice == "bar" or choice == "baz")
        end)

        it("Can return a new table of more than one randomly selected element", function ()
            local count = 10
            local choices = chance.pick({"foo", "bar", "baz"}, count)
            assert.equals(count, #choices)
        end)
    end)

    describe("chance.shuffle()", function ()
        it("Returns an array of randomly shuffled elements", function ()
            local original = { "foo", "bar", "baz" }
            local shuffled = chance.shuffle(original)

            assert.equal(#shuffled, #original)

            local exists = function (element, array)
                local exists = false

                for _,value in ipairs(array) do
                    if element == value then
                        exists = true
                        break
                    end
                end

                assert.is_true(exists)
            end

            for _,value in ipairs(original) do
                exists(value, shuffled)
            end
        end)
    end)

end)

describe("The Miscellaneous API", function ()

    before_each(function () chance.seed(os.time()) end)

    describe("chance.hash()", function ()
        it("Returns a 40 digit hexadecimal number as a string by default", function ()
            local hash = chance.hash()
            assert.is.equal(hash:len(), 40)
            assert.is.truthy(hash:match("^%x+$"))
        end)

        it("Can return a hash with an specific number of digits", function ()
            local count = 10
            local hash = chance.hash { digits = count }
            assert.is.equal(hash:len(), count)
        end)
    end)

    describe("chance.rpg()", function ()
        it("Creates an array of numbers simulating table-top RPG die rolls", function ()
            local oneD100 = chance.rpg("1d100")
            local threeD6 = chance.rpg("3D6")
            local fiveD20 = chance.rpg("5d20")

            assert.equals(1, #oneD100)
            assert.equals(3, #threeD6)
            assert.equals(5, #fiveD20)

            local testRolls = function (rolls, max)
                for _,value in ipairs(rolls) do
                    assert.is.within_range(value, 1, max)
                end
            end

            testRolls(oneD100, 100)
            testRolls(threeD6, 6)
            testRolls(fiveD20, 20)
        end)
    end)

    it("Has predefined functions for common die rolls", function ()
        local dice = { 4, 6, 8, 10, 12, 20, 100 }

        for _,die in ipairs(dice) do
            assert.is.within_range(chance["d" .. die](), 1, die)
        end
    end)

    describe("chance.n()", function ()
        it("Can create an array of data from any other function", function ()
            local strings = chance.n(chance.string, 3)
            assert.equals(3, #strings)
        end)

        it("Passes on extra arguments to the generator function", function ()
            local numbers = chance.n(chance.natural, 10, { max = 3 })
            assert.equals(10, #numbers)
            for _,value in ipairs(numbers) do
                assert.is.within_range(value, 0, 3)
            end
        end)
    end)

    describe("chance.unique()", function ()
        it("Creates an array of unique data from a generator function", function ()
            assert.is.unique_array(chance.unique(chance.month, 3))
        end)

        it("Passes additional arguments to the generator function", function ()
            assert.is.unique_array(chance.unique(chance.character, 3, { pool = "aeiou" }))
        end)
    end)

end)
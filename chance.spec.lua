local chance = require("chance")
local assert = require("luassert")
local say    = require("say")

say:set_namespace("en")

-- This assertion requires two arguments: a pattern (as a string) and
-- another string to test against that pattern.  In this context
-- "pattern" means the kind acceptable to string.match() and similar
-- standard Lua functions.  This assertion is true if the given string
-- matches the pattern.
local function like_pattern(state, arguments)
    local pattern = arguments[1]
    local datum = arguments[2]
    return string.match(datum, pattern) ~= nil
end

say:set("assertion.like_pattern.positive", "Expected pattern %s to match the string:\n%s")
say:set("assertion.like_pattern.negative", "Expected pattern %s to not match the string:\n%s")
assert:register("assertion", "like_pattern", like_pattern,
                "assertion.like_pattern.positive",
                "assertion.like_pattern.negative")

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
        assert.has_no.errors(function () chance.core.seed(os.time()) end)
        assert.has.errors(function () chance.core.seed("foo") end)
    end)

    describe("chance.core.random()", function ()

        before_each(function () chance.core.seed(os.time()) end)

        it("Returns a number in the range [0, 1) given no arguments", function ()
            assert.is.within_range(chance.core.random(), 0, 1, { exclusiveMax = true })
        end)

        it("Returns a number in the range [1, m] given one argument", function ()
            assert.is.within_range(chance.core.random(5), 1, 5)
        end)

        it("Returns a number in the range [m, n] given two arguments", function ()
            assert.is.within_range(chance.core.random(5, 10), 5, 10)
        end)

    end)

    describe("Data sets, i.e. the chance.core.dataSets table", function ()
        local setName, setData

        setup(function ()
            setName = "testNames"
            setData = { "Eric", "Jeff", "Mira", "Ben" }
        end)

        it("Provides chance.core.set() to create data sets and chance.core.fromSet() to get data", function ()
            chance.core.set(setName, setData)
            assert.is.truthy(chance.core.dataSets[setName])
            assert.is.equal(chance.core.dataSets[setName], setData)
            assert.is.in_array(chance.core.fromSet(setName), setData)
        end)

        it("Can create a data set by giving a function to chance.core.set()", function ()
            local generator = function ()
                return chance.helpers.pick(setData)
            end
            chance.core.set(setName, generator)
            assert.is.in_array(chance.core.fromSet(setName), setData)
        end)

        it("Can add data to an existing set via chance.core.appendSet()", function ()
            chance.core.set(setName, setData)
            local oldSize = #setData
            assert.is.equal(chance.core.dataSets[setName], setData)

            chance.core.appendSet(setName, { "Lobby" })
            local newSize = #setData
            assert.is.equal(#chance.core.dataSets[setName], newSize)
        end)

        it("Can overwrite an existing data set via chance.core.set()", function ()
            chance.core.set(setName, setData)
            assert.is.in_array(chance.core.fromSet(setName), setData)
            chance.core.set(setName, { "Foo" })
            assert.is.in_array(chance.core.fromSet(setName), { "Foo" })
            assert.is.not_in_array(chance.core.fromSet(setName), setData)
        end)
    end)
end)


describe("The Basic API", function ()

    before_each(function () chance.core.seed(os.time()) end)

    describe("chance.basic.bool()", function ()
        it("Can return true with a given probability", function ()
            assert.equals(true, chance.basic.bool { probability = 100 })
            assert.equals(false, chance.basic.bool { probability = 0 })
        end)
    end)

    describe("chance.basic.float()", function ()
        it("Returns a number in the range [0,1)", function ()
            assert.is.within_range(chance.basic.float(), 0, 1, { exclusiveMax = true })
        end)
    end)

    describe("chance.basic.integer()", function ()
        it("Returns a number in the range (-INF, INF) given no arguments", function ()
            assert.is.within_range(chance.basic.integer(), -math.huge, math.huge)
        end)

        it("Allows explicitly restricting the minimum and maximum ranges", function ()
            assert.is.within_range(chance.basic.integer { min = 0 }, 0, math.huge)
            assert.is.within_range(chance.basic.integer { max = 1 }, -math.huge, 1)
            assert.is.within_range(chance.basic.integer { min = 1, max = 3 }, 1, 3)
        end)
    end)

    describe("chance.basic.natural()", function ()
        it("Returns a number in the range [0, INF) given no arguments", function ()
            assert.is.within_range(chance.basic.natural(), 0, math.huge)
        end)

        it("Allows explicitly restricting the minimum and maximum ranges", function ()
            assert.is.within_range(chance.basic.natural { min = 1 }, 1, math.huge)
            assert.is.within_range(chance.basic.natural { max = 1 }, 0, 1)
            assert.is.within_range(chance.basic.natural { min = 1, max = 3 }, 1, 3)
        end)

        it("Will not produce negative numbers", function ()
            assert.equals(0, chance.basic.natural { min = -10, max = 0 })
        end)
    end)

    describe("chance.basic.character()", function ()
        it("Can return a random character from a given pool", function ()
            assert.equals("a", chance.basic.character { pool = "a" })
        end)

        it("Gives explicit pools precedence over predefined groups", function ()
            assert.equals("a", chance.basic.character { pool = "a", group = "digit" })
        end)
    end)

    describe("chance.basic.string()", function ()
        it("Can generate strings of a fixed length", function ()
            assert.equals(5, string.len(chance.basic.string { length = 5 }))
        end)
    end)

end)


describe("The Text API", function ()

    before_each(function () chance.core.seed(os.time()) end)

    describe("chance.text.syllable()", function ()
        it("Returns syllables of two to six characters in length", function ()
            assert.is.within_range(string.len(chance.text.syllable()), 2, 6)
        end)
    end)

    describe("chance.text.word()", function ()
        it("Returns a word of one to three syllables by default", function ()
            assert.is.within_range(string.len(chance.text.word()), 2, 18)
        end)

        it("Can create words with a specific number of syllables", function ()
            local word = chance.text.word { syllables = 10 }
            assert.is.within_range(string.len(word), 20, 60)
        end)
    end)

    describe("chance.text.sentence()", function ()
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
            local words = split_string(chance.text.sentence())
            assert.is.within_range(#words, 12, 18)
        end)

        it("Can return a sentence with a specific number of words", function ()
            local count = 5
            local words = split_string(chance.text.sentence { words = count })
            assert.is.equal(#words, count)
        end)
    end)

    describe("chance.text.paragraph()", function ()
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
            local sentences = split_string(chance.text.paragraph())
            assert.is.within_range(#sentences, 3, 7)
        end)

        it("Can generate a specific number of sentences", function ()
            local count = 10
            local sentences = split_string(chance.text.paragraph { sentences = count })
            assert.is.equal(#sentences, count)
        end)
    end)

end)


describe("The Person API", function ()

    before_each(function () chance.core.seed(os.time()) end)

    describe("chance.person.prefix()", function ()
        it("Returns a short prefix by default", function ()
            assert.is.in_array(chance.person.prefix(), chance.core.dataSets["prefixes"]["short"])
        end)

        it("Can return a long prefix", function ()
            assert.is.in_array(chance.person.prefix { type = "long" }, chance.core.dataSets["prefixes"]["long"])
        end)
    end)

    describe("chance.person.suffix()", function ()
        it("Returns a short suffix by default", function ()
            assert.is.in_array(chance.person.suffix(), chance.core.dataSets["suffixes"]["short"])
        end)

        it("Can return a long suffix", function ()
            assert.is.in_array(chance.person.suffix { type = "long" }, chance.core.dataSets["suffixes"]["long"])
        end)
    end)

    describe("chance.person.gender()", function ()
        it("Returns a value from the 'genders' data set by default", function ()
            assert.in_array(chance.person.gender(), chance.core.dataSets["genders"])
        end)

        it("Can be restricted to binary Male or Female", function ()
            assert.in_array(chance.person.gender { binary = true }, { "Male", "Female" })
        end)

        it("Supports customizing its output domain via data sets", function ()
            local genders = { "M", "F", "N" }
            chance.core.set("genders", genders)
            assert.in_array(chance.person.gender(), chance.core.dataSets["genders"])
        end)
    end)

    describe("chance.person.age()", function ()
        it("Returns an age in the range [1, 120] by default", function ()
            assert.is.within_range(chance.person.age(), 1, 120)
        end)

        it("Has predefined age types", function ()
            assert.is.within_range(chance.person.age { type = "child" }, 1, 12)
            assert.is.within_range(chance.person.age { type = "teen" }, 13, 19)
            assert.is.within_range(chance.person.age { type = "adult" }, 18, 65)
            assert.is.within_range(chance.person.age { type = "senior" }, 65, 100)
        end)
    end)

    describe("chance.person.ssn()", function ()
        it("Creates a random United States Social Security Number", function ()
            assert.is.like_pattern("^%d%d%d%-%d%d%-%d%d%d%d$", chance.person.ssn())
        end)

        it("Never creates all zeros for any part of the number", function ()
            local ssn = chance.person.ssn()
            assert.is_not.like_pattern("^000%-%d%d%-%d%d%d%d$", ssn)
            assert.is_not.like_pattern("^%d%d%d%-00%-%d%d%d%d$", ssn)
            assert.is_not.like_pattern("^%d%d%d%-%d%d%-0000$", ssn)
        end)

        it("Never uses 666 or 900-999 for the first three digits", function ()
            local ssn = chance.person.ssn()
            assert.is_not.like_pattern("^666%-%d%d%-%d%d%d%d$", ssn)
            assert.is_not.like_pattern("^9%d%d%-%d%d%-%d%d%d%d$", ssn)
        end)
    end)

end)


describe("The Time API", function ()

    before_each(function () chance.core.seed(os.time()) end)

    it("Can generate random hours", function ()
        assert.is.within_range(chance.time.hour(), 1, 12)
        assert.is.within_range(chance.time.hour { twentyfour = true }, 1, 24)
    end)

    it("Can generate random minutes", function ()
        assert.is.within_range(chance.time.minute(), 0, 59)
    end)

    it("Can generate random seconds", function ()
        assert.is.within_range(chance.time.second(), 0, 59)
    end)

    it("Can generate random milliseconds", function ()
        assert.is.within_range(chance.time.millisecond(), 0, 999)
    end)

    it("Can randomly produce 'am' or 'pm' for times", function ()
        local meridiem = chance.time.ampm()
        assert.is_true(meridiem == "am" or meridiem == "pm")
    end)

    describe("chance.time.year()", function ()
        it("By default returns a year between the current and a century later", function ()
            local random_year = chance.time.year()
            local current_date = os.date("*t")
            assert.is.within_range(random_year, current_date["year"], current_date["year"] + 100)
        end)

        it("Can be restricted to a minimum and/or maximum range", function ()
            local current_date = os.date("*t")
            assert.is.within_range(chance.time.year { min = 1700 }, 1700, 1800)
            assert.is.within_range(chance.time.year { max = 2200 }, current_date["year"], 2200)
            assert.is.within_range(chance.time.year { min = 1984, max = 2002 }, 1984, 2002)
        end)
    end)

    it("Can randomly generate a month by name", function ()
        assert.in_array(chance.time.month(), chance.core.dataSets["months"])
    end)

    it("Can generate a random Unix timestamp", function ()
        assert.is.within_range(chance.time.timestamp(), 0, os.time())
    end)

    describe("chance.time.day()", function ()
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
            assert.in_array(chance.time.day(), alldays)
        end)

        it("Can return only weekdays", function ()
            assert.in_array(chance.time.day { weekdays = true }, weekdays)
            assert.in_array(chance.time.day { weekends = false }, weekdays)
        end)

        it("Can return only weekends", function ()
            assert.in_array(chance.time.day { weekends = true }, weekends)
            assert.in_array(chance.time.day { weekdays = false }, weekends)
        end)
    end)

end)


describe("The Web API", function ()

    before_each(function () chance.core.seed(os.time()) end)

    describe("chance.web.color()", function ()
        local hexPattern = "^#%x+$"

        it("Returns a color in six-digit hexadecimal format by default", function ()
            local color = chance.web.color()
            assert.is.like_pattern(hexPattern, color)
            assert.is.equal(string.len(color), 7)
        end)

        it("Can return a color in short hexadecimal format", function ()
            local color = chance.web.color { format = "shorthex" }
            assert.is.like_pattern(hexPattern, color)
            assert.is.equal(string.len(color), 4)
        end)

        it("Can return a color in rgb() format", function ()
            local color = chance.web.color { format = "rgb" }
            for r,g,b in string.gmatch(color, "^rgb%(%s?(%d+),%s?(%d+),%s?(%d+)%s?%)$") do
                assert.is.truthy(r >= 0 and r <= 255)
                assert.is.truthy(g >= 0 and g <= 255)
                assert.is.truthy(b >= 0 and b <= 255)
            end
        end)

        it("Can return a random greyscale color", function ()
            local hexColor = chance.web.color { greyscale = true }
            local rgbColor = chance.web.color { greyscale = true, format = "rgb" }
            assert.is.like_pattern("^#(%x+)%1%1$", hexColor)
            assert.is.like_pattern("^rgb%((%d+), %1, %1%)$", rgbColor)
        end)
    end)

    describe("chance.web.ip()", function ()
        local ipPattern = "^(%d+)%.(%d+)%.(%d+)%.(%d+)$"

        local extractOctets = function (ip)
            local octets = {}
            for value in string.gmatch(ip, "(%d+)") do
                table.insert(octets, tonumber(value))
            end
            return octets
        end

        it("Returns a completely random IP address by default", function ()
            local ip = chance.web.ip()
            assert.is.like_pattern(ipPattern, ip)
            for _,octet in ipairs(extractOctets(ip)) do
                assert.is_true(octet >= 0 and octet <= 255)
            end
        end)

        it("Can create IP addresses of the A class", function ()
            local ip = chance.web.ip { class = "A" }
            local octets = extractOctets(ip)
            assert.is.like_pattern(ipPattern, ip)
            assert.is_true(octets[1] >= 0 and octets[1] <= 127)
            for i = 2, 4 do
                assert.is_true(octets[i] >= 0 and octets[i] <= 255)
            end
        end)

        it("Can create IP addresses of the B class", function ()
            local ip = chance.web.ip { class = "B" }
            local octets = extractOctets(ip)
            assert.is.like_pattern(ipPattern, ip)
            assert.is_true(octets[1] >= 128 and octets[1] <= 191)
            for i = 2, 4 do
                assert.is_true(octets[i] >= 0 and octets[i] <= 255)
            end
        end)

        it("Can create IP addresses of the C class", function ()
            local ip = chance.web.ip { class = "C" }
            local octets = extractOctets(ip)
            assert.is.like_pattern(ipPattern, ip)
            assert.is_true(octets[1] >= 192 and octets[1] <= 223)
            for i = 2, 4 do
                assert.is_true(octets[i] >= 0 and octets[i] <= 255)
            end
        end)

        it("Can set explicit values for octets", function ()
            local ip = chance.web.ip { octets = { 192, 168 }}
            local octets = extractOctets(ip)
            assert.is.like_pattern(ipPattern, ip)
            assert.is.equal(octets[1], 192)
            assert.is.equal(octets[2], 168)
            for i = 3, 4 do
                assert.is_true(octets[i] >= 0 and octets[i] <= 255)
            end
        end)
    end)

    describe("chance.web.ipv6()", function ()
        it("Returns a random IPv6 address", function ()
            assert.is.like_pattern("^%x+:%x+:%x+:%x+:%x+:%x+:%x+:%x+$", chance.web.ipv6())
        end)
    end)

    describe("chance.web.tld()", function ()
        it("Returns a random top-level domain from the 'tlds' data set", function ()
            assert.is.in_array(chance.web.tld(), chance.core.dataSets["tlds"])
        end)
    end)

    describe("chance.web.domain()", function ()
        it("Returns a domain of random words and a random TLD by default", function ()
            local domain = chance.web.domain()
            for name,tld in string.gmatch(domain, "(%w+)%.([%w%.]+)") do
                -- The length of one to three words.
                assert.is.within_range(string.len(name), 2, 54)
                assert.is.in_array(tld, chance.core.dataSets["tlds"])
            end
        end)

        it("Can use an explicit top-level domain", function ()
            local domain = chance.web.domain { tld = "name" }
            for tld in string.gmatch(domain, "%w+%.(%w+)") do
                assert.is.equal(tld, "name")
            end
        end)
    end)

    describe("chance.web.email()", function ()
        it("Returns a random name with a random domain by default", function ()
            local email = chance.web.email()
            for name,domain,tld in string.gmatch(email, "(%w+)@(%w+)%.(%w+)") do
                assert.is.in_array(tld, chance.core.dataSets["tlds"])
            end
        end)

        it("Can create an email address for an explicit domain", function ()
            local email = chance.web.email { domain = "example.com" }
            for name,domain in string.gmatch(email, "(%w+)@([%w%.]+)") do
                assert.is.equal(domain, "example.com")
            end
        end)
    end)

    describe("chance.web.hashtag()", function ()
        it("Returns a Twitter hashtag built of random words", function ()
            assert.is.like_pattern("^#%w+$", chance.web.hashtag())
        end)
    end)

    describe("chance.web.twitter()", function ()
        it("Returns a random Twitter handle/username", function ()
            assert.is.like_pattern("^@%w+$", chance.web.twitter())
        end)
    end)

    describe("chance.web.uri() and chance.web.url()", function ()
        it("Returns a random domain and path by default", function ()
            assert.is.like_pattern("^http://[%w%.]+/%w+$", chance.web.uri())
            assert.is.like_pattern("^http://[%w%.]+/%w+$", chance.web.url())
        end)

        it("Allows setting an explicit path", function ()
            local path = "foo/bar"
            assert.is.like_pattern("^http://[%w%.]+/" .. path .. "$",
                                   chance.web.uri { path = path })
            assert.is.like_pattern("^http://[%w%.]+/" .. path .. "$",
                                   chance.web.url { path = path })
        end)

        it("Allows setting an explicit domain", function ()
            local domain = "www.example.com"
            assert.is.like_pattern("^http://" .. domain .. "/%w+$",
                                   chance.web.uri { domain = domain })
        end)

        it("Allows setting an explicit protocol", function ()
            local protocol = "ftp"
            assert.is.like_pattern("^" .. protocol .. "://[%w%.]+/%w+$",
                                   chance.web.uri { protocol = protocol })
            assert.is.like_pattern("^" .. protocol .. "://[%w%.]+/%w+$",
                                   chance.web.url { protocol = protocol })
        end)

        it("Allows setting explicit possible file extensions", function ()
            local extensions = { "png", "jpeg", "gif" }
            local uri = chance.web.uri { extensions = extensions }
            local url = chance.web.url { extensions = extensions }

            for x in string.gmatch(uri, "%.(%w+)$") do
                assert.is.in_array(x, extensions)
            end

            for x in string.gmatch(url, "%.(%w+)$") do
                assert.is.in_array(x, extensions)
            end
        end)
    end)

end)


describe("The Poker API", function ()

    before_each(function () chance.core.seed(os.time()) end)

    describe("chance.poker.card()", function ()
        it("Returns a random card as a table with two keys, 'rank' and 'suit,", function ()
            local card = chance.poker.card()
            assert.is.in_array(card.rank, chance.core.dataSets["cards"]["ranks"])
            assert.is.in_array(card.suit, chance.core.dataSets["cards"]["suits"])
        end)

        it("Accepts a boolean flag to never return the Joker", function ()
            assert.has_no.errors(function ()
                for _ = 1, 1000 do
                    local card = chance.poker.card { joker = false }
                    if card.rank == "Joker" and card.suit == "Joker" then
                        error("Generated the Joker when it should never do so")
                    end
                end
            end)
        end)

        it("Can return cards of a specific rank and/or suit", function ()
            local heart = chance.poker.card { suit = "Heart" }
            local duece = chance.poker.card { rank = 2 }
            local AOS = chance.poker.card { rank = "Ace", suit = "Spade" }
            assert.is.equal(heart.suit, "Heart")
            assert.is.equal(duece.rank, 2)
            assert.is.equal(AOS.rank, "Ace")
            assert.is.equal(AOS.suit, "Spade")
        end)
    end)

    describe("chance.poker.deck()", function ()
        it("Returns a 52-card deck by default", function ()
            local deck = chance.poker.deck()
            assert.is.equal(#deck, 52)
            assert.is.unique_array(deck)
        end)

        it("Accepts an optional flag to include the Joker", function ()
            local deck = chance.poker.deck { joker = true }
            assert.is.equal(#deck, 53)
            assert.is.unique_array(deck)
        end)
    end)

end)


describe("The Helper API", function ()

    before_each(function () chance.core.seed(os.time()) end)

    describe("chance.helpers.pick()", function ()
        it("Randomly selects an element from a table", function ()
            local choice = chance.helpers.pick({"foo", "bar", "baz"})
            assert.is_true(choice == "foo" or choice == "bar" or choice == "baz")
        end)

        it("Can return a new table of more than one randomly selected element", function ()
            local count = 10
            local choices = chance.helpers.pick({"foo", "bar", "baz"}, count)
            assert.equals(count, #choices)
        end)
    end)

    describe("chance.helpers.pick_unique()", function ()
        it("Returns a random selection of unique elements from a table", function ()
            assert.is.unique_array(chance.helpers.pick_unique(chance.core.dataSets["months"], 10))
        end)
    end)

    describe("chance.helpers.shuffle()", function ()
        it("Returns an array of randomly shuffled elements", function ()
            local original = { "foo", "bar", "baz" }
            local shuffled = chance.helpers.shuffle(original)

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

    before_each(function () chance.core.seed(os.time()) end)

    describe("chance.misc.normal()", function ()
        it("Returns a number with a mean of zero a standard deviation of one by default", function ()
            assert.is.within_range(chance.misc.normal(), -2, 2)
        end)

        it("Accepts an optional mean", function ()
            assert.is.within_range(chance.misc.normal { mean = 100 }, 98, 102)
        end)

        it("Accepts an optional standard deviation", function ()
            assert.is.within_range(chance.misc.normal { mean = 100, deviation = 15 }, 85, 115)
        end)
    end)

    describe("chance.misc.weighted()", function ()
        it("Returns a random element from an array based on given weights", function ()
            local iteration = 1
            local countA, countB = 0, 0

            repeat
                local choice = chance.misc.weighted({"a", "b"}, {10, 1})

                if choice == "a" then
                    countA = countA + 1
                elseif choice == "b" then
                    countB = countB + 1
                end

                iteration = iteration + 1
            until iteration == 100

            assert.is_true(countA >= countB)
        end)

        it("Returns nil if the arguments do not have the same length", function ()
            assert.is.equal(nil, chance.misc.weighted({"foo"}, {1, 2, 3}))
        end)
    end)

    describe("chance.misc.hash()", function ()
        it("Returns a 40 digit hexadecimal number as a string by default", function ()
            local hash = chance.misc.hash()
            assert.is.equal(hash:len(), 40)
            assert.is.truthy(hash:match("^%x+$"))
        end)

        it("Can return a hash with an specific number of digits", function ()
            local count = 10
            local hash = chance.misc.hash { digits = count }
            assert.is.equal(hash:len(), count)
        end)
    end)

    describe("chance.misc.rpg()", function ()
        it("Creates an array of numbers simulating table-top RPG die rolls", function ()
            local oneD100 = chance.misc.rpg("1d100")
            local threeD6 = chance.misc.rpg("3D6")
            local fiveD20 = chance.misc.rpg("5d20")

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
            assert.is.within_range(chance.misc["d" .. die](), 1, die)
        end
    end)

    describe("chance.misc.n()", function ()
        it("Can create an array of data from any other function", function ()
            local strings = chance.misc.n(chance.basic.string, 3)
            assert.equals(3, #strings)
        end)

        it("Passes on extra arguments to the generator function", function ()
            local numbers = chance.misc.n(chance.basic.natural, 10, { max = 3 })
            assert.equals(10, #numbers)
            for _,value in ipairs(numbers) do
                assert.is.within_range(value, 0, 3)
            end
        end)
    end)

    describe("chance.misc.unique()", function ()
        it("Creates an array of unique data from a generator function", function ()
            assert.is.unique_array(chance.misc.unique(chance.time.month, 3))
        end)

        it("Passes additional arguments to the generator function", function ()
            assert.is.unique_array(chance.misc.unique(chance.basic.character, 3, { pool = "aeiou" }))
        end)
    end)

end)

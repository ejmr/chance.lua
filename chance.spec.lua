local chance = require("chance")
local assert = require("luassert")
local say    = require("say")

say:set_namespace("en")

-- This assertion requires three arguments, which all must be numbers.
-- The assertion is true if the first number is within the range of
-- the second and third numbers, the minimum and maximum of the range,
-- respectively.  By default the test is inclusive.  However, an
-- optional fourth argument can be a table with the key-value pair
-- "exclusiveMax = true".  If present then the test against the
-- maximum value will be exclusive.
local function is_within_range(state, arguments)
    local value = arguments[1]
    local minimum = arguments[2]
    local maximum = arguments[3]

    if arguments[4] and arguments[4]["exclusiveMax"] == true then
        return value >= minimum and value < maximum
    else
        return value >= minimum and value <= maximum
    end
end

say:set("assertion.is_within_range.positive", "Expected value %s to be within range:\n%s and %s")
say:set("assertion.is_within_range.negative", "Expected value %s to not be within range:\n%s and %s")
assert:register("assertion", "is_within_range", is_within_range,
                "assertion.is_within_range.positive",
                "assertion.is_within_range.negative")

describe("The Core API", function ()

    it("Accepts a number to seed the RNG", function ()
        assert.has_no.errors(function () chance.seed(1) end)
        assert.has.errors(function () chance.seed("foo") end)
    end)

    describe("chance.random()", function ()

        before_each(function () chance.seed(1) end)

        it("Returns a number in the range [0, 1) given no arguments", function ()
            assert.is_within_range(chance.random(), 0, 1, { exclusiveMax = true })
        end)

        it("Returns a number in the range [1, m] given one argument", function ()
            assert.is_within_range(chance.random(5), 1, 5)
        end)

        it("Returns a number in the range [m, n] given two arguments", function ()
            assert.is_within_range(chance.random(5, 10), 5, 10)
        end)

    end)
end)

describe("The Basic API", function ()

    before_each(function () chance.seed(1) end)

    describe("chance.bool()", function ()
        it("Can return true with a given probability", function ()
            assert.equals(true, chance.bool { probability = 100 })
            assert.equals(false, chance.bool { probability = 0 })
        end)
    end)

    describe("chance.float()", function ()
        it("Returns a number in the range [0,1)", function ()
            assert.is_within_range(chance.float(), 0, 1, { exclusiveMax = true })
        end)
    end)

    describe("chance.integer()", function ()
        it("Returns a number in the range (-INF, INF) given no arguments", function ()
            assert.is_within_range(chance.integer(), -math.huge, math.huge)
        end)

        it("Allows explicitly restricting the minimum and maximum ranges", function ()
            assert.is_within_range(chance.integer { min = 0 }, 0, math.huge)
            assert.is_within_range(chance.integer { max = 1 }, -math.huge, 1)
            assert.is_within_range(chance.integer { min = 1, max = 3 }, 1, 3)
        end)
    end)

    describe("chance.natural()", function ()
        it("Returns a number in the range [0, INF) given no arguments", function ()
            assert.is_within_range(chance.natural(), 0, math.huge)
        end)

        it("Allows explicitly restricting the minimum and maximum ranges", function ()
            assert.is_within_range(chance.natural { min = 1 }, 1, math.huge)
            assert.is_within_range(chance.natural { max = 1 }, 0, 1)
            assert.is_within_range(chance.natural { min = 1, max = 3 }, 1, 3)
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

describe("The Time API", function ()

    before_each(function () chance.seed(1) end)

    it("Can generate random hours", function ()
        assert.is_within_range(chance.hour(), 1, 12)
        assert.is_within_range(chance.hour { twentyfour = true }, 1, 24)
    end)

    it("Can generate random minutes", function ()
        assert.is_within_range(chance.minute(), 0, 59)
    end)

    it("Can generate random seconds", function ()
        assert.is_within_range(chance.second(), 0, 59)
    end)

    it("Can generate random milliseconds", function ()
        assert.is_within_range(chance.millisecond(), 0, 999)
    end)

    it("Can randomly produce 'am' or 'pm' for times", function ()
        local meridiem = chance.ampm()
        assert.is_true(meridiem == "am" or meridiem == "pm")
    end)

end)

describe("The Helper API", function ()

    before_each(function () chance.seed(1) end)

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

    before_each(function () chance.seed(1) end)

    describe("chance.rpg()", function ()
        it("Creates an array of numbers simulating table-top RPG die rolls", function ()
            local oneD100 = chance.rpg("1d100")
            local threeD6 = chance.rpg("3d6")
            local fiveD20 = chance.rpg("5d20")

            assert.equals(1, #oneD100)
            assert.equals(3, #threeD6)
            assert.equals(5, #fiveD20)

            local testRolls = function (rolls, max)
                for _,value in ipairs(rolls) do
                    assert.is_within_range(value, 1, max)
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
            assert.is_within_range(chance["d" .. die](), 1, die)
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
                assert.is_within_range(value, 0, 3)
            end
        end)
    end)

end)
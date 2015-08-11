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
-- Import LuaUnit module
local lu = require('luaunit')

local Gene = require('machinelearning.ai.model.Gene')

TestGene = {}

function TestGene:testConstructor()
    local subject1 = Gene.new()
    local subject2 = Gene.new()

    -- assert points don't match
    lu.assertFalse(subject1 == subject2)
    lu.assertFalse(subject1.into == subject2.into)
    lu.assertFalse(subject1.out == subject2.out)

    -- assert values are equal
    lu.assertEquals(subject1, subject2)
end

function TestGene:testCopy()
    local subject = Gene.new()
    local result = Gene.copy(subject)

    -- assert points don't match
    lu.assertFalse(result == subject)
    lu.assertFalse(result.into == subject.into)
    lu.assertFalse(result.out == subject.out)

    -- assert values are equal
    lu.assertEquals(result, result)
end

if not fullTestSuite then
    -- Run the tests
    os.exit(lu.LuaUnit.run())
end
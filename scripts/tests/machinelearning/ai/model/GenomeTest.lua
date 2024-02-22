-- Import LuaUnit module
local lu = require('lib.luaunit')

local Genome = require('machinelearning.ai.model.Genome')
local Gene = require('machinelearning.ai.model.Gene')

-- luacheck: globals TestGenome fullTestSuite
TestGenome = {}

function TestGenome.testConstructor()
    local subject1 = Genome:new()
    local subject2 = Genome:new()

    lu.assertFalse(subject1 == subject2)
    lu.assertFalse(subject1.mutationRates == subject2.mutationRates)
    lu.assertEquals(subject1, subject2)

    subject1.genes[1] = Gene.new()
    subject2.genes[1] = Gene.new()

    lu.assertFalse(subject1.genes == subject2.genes)
    lu.assertFalse(subject1.genes[1] == subject2.genes[1])
end

function TestGenome.testCopy()
    local subjectGenome = Genome:new()
    local gene1 = Gene.new()
    subjectGenome.genes[1] = gene1

    local result = Genome.copy(subjectGenome)

    lu.assertFalse(result == subjectGenome)

    lu.assertNotNil(result.genes[1])
    lu.assertFalse(result.genes[1] == subjectGenome.genes[1])

    lu.assertFalse(result.mutationRates == subjectGenome.mutationRates)
end

if not fullTestSuite then
    -- Run the tests
    os.exit(lu.LuaUnit.run())
end
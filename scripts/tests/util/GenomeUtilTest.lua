-- Import LuaUnit module
local lu = require('luaunit')

local GenomeUtil = require('util.GenomeUtil')
local MathUtil = require('util.MathUtil')

-- Test the RandomNumber class
TestGenomeUtil = {}

function TestGenomeUtil:setUp()
    MathUtil.init(12345)
end

function TestGenomeUtil:testDistribute()
    for _=1, 1000 do
        local result = GenomeUtil.generateRandomWeight()
        lu.assertTrue(result >= -2)
        lu.assertTrue(result <= 2)
    end
end

function TestGenomeUtil:testGetTwoRandomGenomes()
    local genomes = {
        { id = 1, fitness = 0.5 },
        { id = 2, fitness = 0.8 },
        { id = 3, fitness = 0.3 },
        { id = 4, fitness = 0.7 }
    }

    local resultA, resultB = GenomeUtil.getTwoRandomGenomes(genomes)

    lu.assertEquals(resultA.id, 4)
    lu.assertEquals(resultB.id, 3)

    resultA, resultB = GenomeUtil.getTwoRandomGenomes(genomes)
    lu.assertEquals(resultA.id, 4)
    lu.assertEquals(resultB.id, 2)

    resultA, resultB = GenomeUtil.getTwoRandomGenomes(genomes)
    lu.assertEquals(resultA.id, 3)
    lu.assertEquals(resultB.id, 2)
end

function TestGenomeUtil:testGetGenomeWithHighestFitness()
    local genomes = {
        { id = 1, fitness = 0.5 },
        { id = 2, fitness = 0.8 },
        { id = 3, fitness = 0.3 },
        { id = 4, fitness = 0.7 },
        { id = 4, fitness = 0.1 }
    }

    local result = GenomeUtil.getGenomeWithHighestFitness(genomes)

    lu.assertEquals(result.fitness, 0.8)
end

if not fullTestSuite then
    -- Run the tests
    os.exit(lu.LuaUnit.run())
end
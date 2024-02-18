-- Import LuaUnit module
local lu = require('luaunit')

local GenomeUtil = require('util.GenomeUtil')
local MathUtil = require('util.MathUtil')

-- luacheck: globals TestGenomeUtil Properties fullTestSuite
TestGenomeUtil = {}

function TestGenomeUtil.setUp()
    MathUtil.init(12345)
end

function TestGenomeUtil.testDistribute()
    for _=1, 1000 do
        local result = GenomeUtil.generateRandomWeight()
        lu.assertTrue(result >= -2)
        lu.assertTrue(result <= 2)
    end
end

function TestGenomeUtil.testGetTwoRandomGenomes()
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

function TestGenomeUtil.testGetGenomeWithHighestFitness()
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

function TestGenomeUtil.testIsSameSpecies()
    -- Mock genome objects
    local genome1 = {
        genes = {
            { innovation = 1, weight = 0.5 },
            { innovation = 2, weight = -0.3 },
            { innovation = 3, weight = 0.8 }
        }
    }
    local genome2 = {
        genes = {
            { innovation = 2, weight = -0.2 },
            { innovation = 3, weight = 0.9 },
            { innovation = 4, weight = 0.4 }
        }
    }

    -- Mock properties
    Properties = {
        deltaDisjoint = 0.1,
        deltaWeights = 0.2,
        deltaThreshold = 0.5
    }

    -- Call the function to check if the genomes are in the same species
    local sameSpecies = GenomeUtil.isSameSpecies(genome1, genome2)

    -- Assert that the genomes are not in the same species based on the mock properties
    lu.assertTrue(sameSpecies)
end

function TestGenomeUtil.testIsSameSpeciesFalse()
    -- Mock genome objects
    local genome1 = {
        genes = {
            { innovation = 1, weight = 0.5 },
            { innovation = 2, weight = -0.3 },
            { innovation = 3, weight = 0.8 }
        }
    }
    local genome2 = {
        genes = {
            { innovation = 1, weight = 4.5 },
            { innovation = 5, weight = 0.9 },
            { innovation = 6, weight = 0.4 }
        }
    }

    -- Mock properties
    Properties = {
        deltaDisjoint = 2.0,
        deltaWeights = 0.4,
        deltaThreshold = 3.0
    }

    -- Call the function to check if the genomes are in the same species
    local sameSpecies = GenomeUtil.isSameSpecies(genome1, genome2)

    lu.assertFalse(sameSpecies)
end

function TestGenomeUtil.testIsSameSpeciesFalseNoneSame()
    -- Mock genome objects
    local genome1 = {
        genes = {
            { innovation = 1, weight = 0.5 },
            { innovation = 2, weight = -0.3 },
            { innovation = 3, weight = 0.8 }
        }
    }
    local genome2 = {
        genes = {
            { innovation = 4, weight = -0.2 },
            { innovation = 5, weight = 0.9 },
            { innovation = 6, weight = 0.4 }
        }
    }

    -- Mock properties
    Properties = {
        deltaDisjoint = 0.1,
        deltaWeights = 0.2,
        deltaThreshold = 0.5
    }

    -- Call the function to check if the genomes are in the same species
    local sameSpecies = GenomeUtil.isSameSpecies(genome1, genome2)

    lu.assertFalse(sameSpecies)
end

if not fullTestSuite then
    -- Run the tests
    os.exit(lu.LuaUnit.run())
end
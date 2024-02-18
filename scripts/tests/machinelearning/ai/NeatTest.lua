-- Import LuaUnit module
local lu = require('luaunit')

require('util.MathUtil').init(12345)
local Neat = require('machinelearning.ai.Neat')
local Pool = require('machinelearning.ai.model.Pool')
local Genome = require('machinelearning.ai.model.Genome')
local Species = require('machinelearning.ai.model.Species')

-- luacheck: globals console TestNeat fullTestSuite
-- To allow ErrorHandler to work
console = {}
function console.log()  end

TestNeat = {}

-- Create a mock pool with species and genomes
local function createMockPool()
    local pool = Pool:new()
    pool.species = {
        {
            genomes = {
                { fitness = 1 }, -- 1
                { fitness = 2 }, -- 2
                { fitness = 10 }, -- 8
                { fitness = 8 }, -- 7
                { fitness = 7 }, -- 6
                { fitness = 3 }, -- 3
                { fitness = 4 }, -- 4
                { fitness = 5 }, -- 5
            },
            topFitness = 0,
        },
        {
            genomes = {
                { fitness = 11 }, -- 9
                { fitness = 12 }, -- 10
                { fitness = 19 }, -- 16
                { fitness = 18 }, -- 15
                { fitness = 17 }, -- 14
                { fitness = 13 }, -- 11
                { fitness = 14 }, -- 12
                { fitness = 15 }, -- 13
            },
            topFitness = 0,
        },
        {
            genomes = {
                { fitness = 1 }, -- 1
                { fitness = 2 }, -- 2
                { fitness = 3 }, -- 3
                { fitness = 1 }, -- 1
                { fitness = 7 }, -- 6
                { fitness = 3 }, -- 3
                { fitness = 4 }, -- 4
                { fitness = 5 }, -- 5
            },
            topFitness = 0,
        },
    }

    return pool
end

function TestNeat.testCullSpecies()
    local pool = createMockPool()
    lu.assertEquals(#pool.species[1].genomes, 8)
    lu.assertEquals(pool:getNumberOfGenomes(), 24)

    Neat.cullSpecies(pool, false)

    lu.assertEquals(#pool.species[1].genomes, 4)
    lu.assertEquals(pool.species[1].genomes[1].fitness, 10)
    lu.assertEquals(pool.species[1].genomes[2].fitness, 8)
    lu.assertEquals(pool.species[1].genomes[3].fitness, 7)
    lu.assertEquals(pool.species[1].genomes[4].fitness, 5)

    lu.assertEquals(#pool.species[2].genomes, 4)
    lu.assertEquals(pool.species[2].genomes[1].fitness, 19)
    lu.assertEquals(pool.species[2].genomes[2].fitness, 18)
    lu.assertEquals(pool.species[2].genomes[3].fitness, 17)
    lu.assertEquals(pool.species[2].genomes[4].fitness, 15)

    lu.assertEquals(#pool.species[3].genomes, 4)
    lu.assertEquals(pool.species[3].genomes[1].fitness, 7)
    lu.assertEquals(pool.species[3].genomes[2].fitness, 5)
    lu.assertEquals(pool.species[3].genomes[3].fitness, 4)
    lu.assertEquals(pool.species[3].genomes[4].fitness, 3)

    lu.assertEquals(pool:getNumberOfGenomes(), 12)
end

function TestNeat.testCullSpeciesToOne()
    local pool = createMockPool()
    lu.assertEquals(#pool.species[1].genomes, 8)

    Neat.cullSpecies(pool, true)

    lu.assertEquals(#pool.species[1].genomes, 1)
    lu.assertEquals(pool.species[1].genomes[1].fitness, 10)
end

function TestNeat.testCullSpeciesSingleGenomeSpecies()
    local pool = Pool:new()

    for i = 1, 300 do
        pool.species[i] = Species:new()
        pool.species[i].genomes[1] = Genome:new()
    end

    lu.assertEquals(pool:getNumberOfGenomes(), 300)

    Neat.cullSpecies(pool, false)

    lu.assertEquals(pool:getNumberOfGenomes(), 300)
end

function TestNeat.testRankGlobally()
    local pool = createMockPool()
    local expectedFirstPlace = pool.species[1].genomes[1]
    local expected8thPlace = pool.species[1].genomes[3]
    local expected16thPlace = pool.species[2].genomes[3]
    lu.assertNil(expectedFirstPlace.globalRank)
    lu.assertNil(expected8thPlace.globalRank)
    lu.assertNil(expected16thPlace.globalRank)
    Neat.rankGlobally(pool)
    lu.assertEquals(expectedFirstPlace.globalRank, 1)
    lu.assertEquals(expected8thPlace.globalRank, 8)
    lu.assertEquals(expected16thPlace.globalRank, 16)
end

function TestNeat.testCalculateAverageFitnessRank()
    local pool = createMockPool()
    Neat.rankGlobally(pool)
    lu.assertNil(pool.species[1].averageFitnessRank)
    lu.assertNil(pool.species[2].averageFitnessRank)
    lu.assertNil(pool.species[3].averageFitnessRank)

    Neat.calculateAverageFitnessRank(pool)

    lu.assertEquals(pool.species[1].averageFitnessRank, 4.5)
    lu.assertEquals(pool.species[2].averageFitnessRank, 12.5)
    lu.assertEquals(pool.species[3].averageFitnessRank, 3.125)
end

function TestNeat.testRemoveStaleSpecies()
    local pool = createMockPool()
    lu.assertEquals(#pool.species, 3)

    Neat.removeStaleSpecies(pool, 15)
    lu.assertEquals(#pool.species, 3)

    for _=1, 15 do
        pool.species[3].genomes[1].fitness = (pool.species[3].genomes[1].fitness + 1)
        Neat.removeStaleSpecies(pool, 15)
    end

    lu.assertEquals(#pool.species, 1)

    for _=1, 15 do
        Neat.removeStaleSpecies(pool, 15)
    end

    lu.assertEquals(#pool.species, 0)
end

function TestNeat.testRemoveStaleSpeciesNonStale()
    local pool = createMockPool()
    lu.assertEquals(#pool.species, 3)

    for _=1, 15 do
        Neat.removeStaleSpecies(pool, 15)
    end
    lu.assertEquals(#pool.species, 3)

    pool.species[1].genomes[1].fitness = pool.species[1].genomes[1].fitness + 1
    Neat.removeStaleSpecies(pool, 15)
    lu.assertEquals(#pool.species, 1)

    for _=1, 12 do
        Neat.removeStaleSpecies(pool, 15)
    end

    lu.assertEquals(#pool.species, 1)
end

function TestNeat.testRemoveWeakSpecies()
    local pool = createMockPool()
    -- add a weak species
    pool.species[4] = {
        genomes = {
            { fitness = 1 },
        },
    }
    -- add a strong species
    pool.species[5] = {
        genomes = {
            { fitness = 111 },
            { fitness = 111 },
            { fitness = 111 },
            { fitness = 111 },
            { fitness = 111 },
            { fitness = 111 },
            { fitness = 111 },
            { fitness = 111 },
        },
    }
    Neat.rankGlobally(pool)
    Neat.calculateAverageFitnessRank(pool)

    lu.assertEquals(#pool.species, 5)

    Neat.removeWeakSpecies(pool)

    -- ensure one was removed
    lu.assertEquals(#pool.species, 4)

    -- ensure weak one was removed and strong one remains
    lu.assertEquals(111, pool.species[4].genomes[1].fitness)
    lu.assertEquals(8, #pool.species[1].genomes)
    lu.assertEquals(8, #pool.species[2].genomes)
    lu.assertEquals(8, #pool.species[3].genomes)
    lu.assertEquals(8, #pool.species[4].genomes)
end

function TestNeat.testInitializePool()
    local neat = Neat:new()

    neat:initializePool(169, 7)
    lu.assertEquals(neat.pool.currentGenome, 1)
    lu.assertEquals(neat.pool.currentSpecies, 1)
    lu.assertEquals(neat.pool:getNumberOfGenomes(), 300)

    -- Make sure all genomes are pointing to different references
    for _, species in pairs(neat.pool.species) do
        for _, genomes in pairs(species.genomes) do
            local numberOfMatches = 0
            for _, species2 in pairs(neat.pool.species) do
                for _, genomes2 in pairs(species2.genomes) do
                    if genomes2 == genomes then
                        numberOfMatches = numberOfMatches + 1
                    end
                end
            end

            lu.assertEquals(numberOfMatches, 1)
        end
    end
end

function TestNeat.testOrderSpeciesFromBestToWorst()
    local neat = Neat:new()
    neat:initializePool(169, 7)

    for _, species in pairs(neat.pool.species) do
        for _, genomes in pairs(species.genomes) do
            genomes.fitness = 1
        end
    end

    local hightFitnessGenome = Genome.new()
    hightFitnessGenome.fitness = 200
    local lowFitnessGenome = Genome.new()
    lowFitnessGenome.fitness = 100

    neat.pool.species[1].genomes[2] = hightFitnessGenome
    neat.pool.species[280].genomes[2] = lowFitnessGenome

    neat.rankGlobally(neat.pool)
    neat.calculateAverageFitnessRank(neat.pool)

    neat:orderSpeciesFromBestToWorst(neat.pool)
    lu.assertEquals(neat.pool.species[1].genomes[1].fitness, 1)
    lu.assertEquals(neat.pool.species[1].genomes[2].fitness, 200)
    lu.assertEquals(neat.pool.species[2].genomes[1].fitness, 1)
    lu.assertEquals(neat.pool.species[2].genomes[2].fitness, 100)

    lu.assertEquals(neat.pool.species[1].averageFitnessRank, 2)
    lu.assertEquals(neat.pool.species[2].averageFitnessRank, 1.5)
end

function TestNeat.testBreedTopSpecies()
    local neat = Neat:new()
    neat:initializePool(169, 7)

    for _, species in pairs(neat.pool.species) do
        for _, genomes in pairs(species.genomes) do
            genomes.fitness = 1
        end
    end

    local hightFitnessGenome = Genome.new()
    hightFitnessGenome.fitness = 200
    local lowFitnessGenome = Genome.new()
    lowFitnessGenome.fitness = 100

    neat.pool.species[1].genomes[2] = hightFitnessGenome
    neat.pool.species[280].genomes[2] = lowFitnessGenome

    ---@type Genome[]
    local resultChildren = neat:breedTopSpecies(neat.pool, 20, 169, 7, true)
    lu.assertEquals(#resultChildren, 20)

    resultChildren = neat:breedTopSpecies(neat.pool, 100, 169, 7, true)
    lu.assertEquals(#resultChildren, 100)
    lu.assertEquals(resultChildren[1].bredFrom, 1)
    lu.assertEquals(resultChildren[2].bredFrom, 1)
    lu.assertEquals(resultChildren[3].bredFrom, 1)
    lu.assertEquals(resultChildren[4].bredFrom, 1)
end

if not fullTestSuite then
    -- Run the tests
    os.exit(lu.LuaUnit.run())
end
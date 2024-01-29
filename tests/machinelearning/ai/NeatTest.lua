-- Import LuaUnit module
local lu = require('luaunit')

require('util.MathUtil').init(12345)
local Neat = require('machinelearning.ai.Neat')
local Pool = require('machinelearning.ai.model.Pool')
local Genome = require('machinelearning.ai.model.Genome')
local Species = require('machinelearning.ai.model.Species')
TestNeat = {}

-- Create a mock pool with species and genomes
local function createMockPool()
    local pool = Pool:new()
    pool.species = {
        {
            genomes = {
                { fitness = 1 }, -- 1
                { fitness = 2 }, -- 4
                { fitness = 10 }, -- 16
                { fitness = 8 }, -- 15
                { fitness = 7 }, -- 13
                { fitness = 3 }, -- 6
                { fitness = 4 }, -- 9
                { fitness = 5 }, -- 11
            },
            topFitness = 0,
        },
        {
            genomes = {
                { fitness = 11 },
                { fitness = 12 },
                { fitness = 19 },
                { fitness = 18 },
                { fitness = 17 },
                { fitness = 13 },
                { fitness = 14 },
                { fitness = 15 },
            },
            topFitness = 0,
        },
        {
            genomes = {
                { fitness = 1 }, -- 2
                { fitness = 2 }, -- 5
                { fitness = 3 }, -- 7
                { fitness = 1 }, -- 3
                { fitness = 7 }, -- 14
                { fitness = 3 }, -- 8
                { fitness = 4 }, -- 10
                { fitness = 5 }, -- 12
            },
            topFitness = 0,
        },
    }

    return pool
end

function TestNeat:testCullSpecies()
    local pool = createMockPool()
    lu.assertEquals(#pool.species[1].genomes, 8)
    lu.assertEquals(pool:getNumberOfGenomes(), 24)

    Neat.cullSpecies(pool, false)

    lu.assertEquals(#pool.species[1].genomes, 4)
    lu.assertEquals(pool.species[1].genomes[1].fitness, 10)
    lu.assertEquals(pool.species[1].genomes[2].fitness, 8)
    lu.assertEquals(pool.species[1].genomes[3].fitness, 7)
    lu.assertEquals(pool.species[1].genomes[4].fitness, 5)

    lu.assertEquals(pool:getNumberOfGenomes(), 12)
end

function TestNeat:testCullSpeciesToOne()
    local pool = createMockPool()
    lu.assertEquals(#pool.species[1].genomes, 8)

    Neat.cullSpecies(pool, true)

    lu.assertEquals(#pool.species[1].genomes, 1)
    lu.assertEquals(pool.species[1].genomes[1].fitness, 10)
end

function TestNeat:testCullSpeciesSingleGenomeSpecies()
    local pool = Pool:new()

    for i = 1, 300 do
        pool.species[i] = Species:new()
        pool.species[i].genomes[1] = Genome:new()
    end

    lu.assertEquals(pool:getNumberOfGenomes(), 300)

    Neat.cullSpecies(pool, false)

    lu.assertEquals(pool:getNumberOfGenomes(), 300)
end

function TestNeat:testRankGlobally()
    local pool = createMockPool()
    local expectedFirstPlace = pool.species[1].genomes[1]
    local expected16thPlace = pool.species[1].genomes[3]
    local expected24thPlace = pool.species[2].genomes[3]
    lu.assertNil(expectedFirstPlace.globalRank)
    lu.assertNil(expected16thPlace.globalRank)
    lu.assertNil(expected24thPlace.globalRank)
    Neat.rankGlobally(pool)
    lu.assertEquals(expectedFirstPlace.globalRank, 1)
    lu.assertEquals(expected16thPlace.globalRank, 16)
    lu.assertEquals(expected24thPlace.globalRank, 24)
end

function TestNeat:testCalculateAverageFitnessRank()
    local pool = createMockPool()
    Neat.rankGlobally(pool)
    lu.assertNil(pool.species[1].averageFitnessRank)
    lu.assertNil(pool.species[2].averageFitnessRank)
    lu.assertNil(pool.species[3].averageFitnessRank)

    Neat.calculateAverageFitnessRank(pool)

    lu.assertEquals(pool.species[1].averageFitnessRank, 9.625)
    lu.assertEquals(pool.species[2].averageFitnessRank, 20.5)
    lu.assertEquals(pool.species[3].averageFitnessRank, 7.375)
end

function TestNeat:testRemoveStaleSpecies()
    local pool = createMockPool()
    lu.assertEquals(#pool.species, 3)

    Neat.removeStaleSpecies(pool)
    lu.assertEquals(#pool.species, 3)

    for _=1, 15 do
        Neat.removeStaleSpecies(pool)
    end

    lu.assertEquals(#pool.species, 1)

    for _=1, 100 do
        Neat.removeStaleSpecies(pool)
    end

    -- Ensure we always keep 1
    lu.assertEquals(#pool.species, 1)
end

function TestNeat:testRemoveWeakSpecies()
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

function TestNeat:testInitializePool()
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

function TestNeat:testOrderSpeciesFromBestToWorst()
    local neat = Neat:new()
    neat:initializePool(169, 7)

    for i, species in pairs(neat.pool.species) do
        for i, genomes in pairs(species.genomes) do
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

    neat.orderSpeciesFromBestToWorst(neat.pool)
    lu.assertEquals(neat.pool.species[1].genomes[1].fitness, 1)
    lu.assertEquals(neat.pool.species[1].genomes[2].fitness, 200)
    lu.assertEquals(neat.pool.species[2].genomes[1].fitness, 1)
    lu.assertEquals(neat.pool.species[2].genomes[2].fitness, 100)

    lu.assertEquals(neat.pool.species[1].averageFitness, 100.5)
    lu.assertEquals(neat.pool.species[2].averageFitness, 50.5)
end

function TestNeat:testBreedTopSpecies()
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

-- Run the tests
os.exit(lu.LuaUnit.run())
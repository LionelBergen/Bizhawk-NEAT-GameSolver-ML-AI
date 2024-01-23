-- Import LuaUnit module
local lu = require('luaunit')

local Neat = require('machinelearning.ai.Neat')
TestNeat = {}

-- Create a mock pool with species and genomes
local function createMockPool()
    local pool = {
        species = {
            {
                genomes = {
                    { fitness = 1 },
                    { fitness = 2 },
                    { fitness = 10 },
                    { fitness = 8 },
                    { fitness = 7 },
                    { fitness = 3 },
                    { fitness = 4 },
                    { fitness = 5 },
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
                    { fitness = 1 },
                    { fitness = 2 },
                    { fitness = 3 },
                    { fitness = 1 },
                    { fitness = 7 },
                    { fitness = 3 },
                    { fitness = 4 },
                    { fitness = 5 },
                },
                topFitness = 0,
            },
        },
        maxFitness = 0,
    }

    return pool
end

function TestNeat:testCullSpecies()
    local pool = createMockPool()
    lu.assertEquals(#pool.species[1].genomes, 8)

    Neat.cullSpecies(pool, false)

    lu.assertEquals(#pool.species[1].genomes, 4)
    lu.assertEquals(pool.species[1].genomes[1].fitness, 10)
    lu.assertEquals(pool.species[1].genomes[2].fitness, 8)
    lu.assertEquals(pool.species[1].genomes[3].fitness, 7)
    lu.assertEquals(pool.species[1].genomes[4].fitness, 5)
end

function TestNeat:testCullSpeciesToOne()
    local pool = createMockPool()
    lu.assertEquals(#pool.species[1].genomes, 8)

    Neat.cullSpecies(pool, true)

    lu.assertEquals(#pool.species[1].genomes, 1)
    lu.assertEquals(pool.species[1].genomes[1].fitness, 10)
end

function TestNeat:testRankGlobally()
    local pool = createMockPool()
    lu.assertNil(pool.species[1].genomes[1].globalRank)
    lu.assertNil(pool.species[1].genomes[3].globalRank)
    Neat.rankGlobally(pool)
    lu.assertEquals(pool.species[1].genomes[1].globalRank, 1)
    lu.assertEquals(pool.species[1].genomes[3].globalRank, 16)
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

-- Run the tests
os.exit(lu.LuaUnit.run())
-- Import LuaUnit module
local lu = require('lib.luaunit')
local Pool = require('machinelearning.ai.model.Pool')

-- luacheck: globals TestPool fullTestSuite
TestPool = {}

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

function TestPool.testGetNumberOfGenomes()
    local pool = createMockPool()

    local result = pool:getNumberOfGenomes()
    lu.assertEquals(result, 24)
end

function TestPool.testGetNumberOfGenomesNone()
    local pool = Pool:new()

    local result = pool:getNumberOfGenomes()
    lu.assertEquals(result, 0)
end


if not fullTestSuite then
    -- Run the tests
    os.exit(lu.LuaUnit.run())
end
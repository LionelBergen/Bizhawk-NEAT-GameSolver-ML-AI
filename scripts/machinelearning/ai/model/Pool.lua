---@class Pool
local Pool = {}
local Species = require('machinelearning.ai.model.Species')

-- innovation number used to track gene.
---@return Pool
function Pool:new(innovation)
    ---@type Pool
    local pool = {}
    self = self or pool
    self.__index = self
    setmetatable(pool, self)

    ---@type Species[]
    pool.species = {}
    pool.generation = 1
    pool.innovation = innovation
    pool.currentSpecies = 1
    pool.currentGenome = 1
    pool.currentFrame = 0
    pool.maxFitness = 0

    return pool
end

function Pool.copy(pool)
    ---@type Pool
    local poolCopy

    if (pool ~= nil) then
        poolCopy = Pool:new()

        poolCopy.generation = pool.generation or poolCopy.generation
        poolCopy.innovation = pool.innovation or poolCopy.innovation
        poolCopy.currentSpecies = pool.currentSpecies or poolCopy.currentSpecies
        poolCopy.currentGenome = pool.currentGenome or poolCopy.currentGenome
        poolCopy.currentFrame = pool.currentFrame or poolCopy.currentFrame
        poolCopy.maxFitness = pool.maxFitness or poolCopy.maxFitness

        poolCopy.species = {}
        for k, v in pairs(pool.species) do
            poolCopy.species[k] = Species.copy(v)
        end
    end

    return poolCopy
end

---@return Species
function Pool:getCurrentSpecies()
    return self.species[self.currentSpecies]
end

---@return Genome
function Pool:getCurrentGenome()
    ---@type Species
    local species = self:getCurrentSpecies()
    return species.genomes[self.currentGenome]
end

function Pool:newInnovation()
    self.innovation = self.innovation + 1
    return self.innovation
end

function Pool:getNumberOfGenomes()
    local totalGenomes = 0

    for _, species in pairs(self.species) do
        totalGenomes = totalGenomes + #species.genomes
    end

    return totalGenomes
end

return Pool
---@class Pool
local Pool = {}

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
    pool.generation = 0
    pool.innovation = innovation
    pool.currentSpecies = 1
    pool.currentGenome = 1
    pool.currentFrame = 0
    pool.maxFitness = 0

    return pool
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

return Pool
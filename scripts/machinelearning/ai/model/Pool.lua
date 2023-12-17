local Pool = {}

-- innovation number used to track gene.
function Pool:new(innovation)
    local pool = {}
    self = self or pool
    self.__index = self
    setmetatable(pool, self)

    pool.species = {}
    pool.generation = 0
    pool.innovation = innovation
    pool.currentSpecies = 1
    pool.currentGenome = 1
    pool.currentFrame = 0
    pool.maxFitness = 0

    return pool
end

function Pool:getCurrentSpecies()
    return self.species[self.currentSpecies]
end

function Pool:getCurrentGenome()
    local species = self:getCurrentSpecies()
    return species.genomes[self.currentGenome]
end

return Pool
local Pool = {}

-- innovation number used to track gene.
function Pool:new(innovation)
    local pool = {}
    pool.species = {}
    pool.generation = 0
    pool.innovation = innovation
    pool.currentSpecies = 1
    pool.currentGenome = 1
    pool.currentFrame = 0
    pool.maxFitness = 0

    return pool
end

return Pool
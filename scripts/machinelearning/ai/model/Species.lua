---@class Species
local Species = {}

---@return Species
function Species.new()
    ---@type Species
    local species = {}

    species.topFitness = 0
    species.staleness = 0
    species.averageFitness = 0
    ---@type Genome[]
    species.genomes = {}

    return species
end

return Species
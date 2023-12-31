---@class Species
local Species = {}

local Genome = require('machinelearning.ai.model.Genome')

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

---@return Species
function Species.copy(species)
    ---@type Species
    local speciesCopy = {}

    if (species ~= nil) then
        speciesCopy = Species.new()

        speciesCopy.topFitness = species.topFitness or speciesCopy.topFitness
        speciesCopy.staleness = species.topFitness or speciesCopy.staleness
        speciesCopy.averageFitness = species.averageFitness or speciesCopy.averageFitness

        speciesCopy.genomes = {}

        for k,v in pairs(species.genomes) do
            speciesCopy.genomes[k] = Genome.copy(v)
        end
    end

    return speciesCopy
end

return Species
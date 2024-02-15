---@class GenerationResults
local GenerationResults = {}

local SpeciesResults = require('machinelearning.ai.model.record.SpeciesResults')

---@param generation number
---@param speciesResults SpeciesResults[]
---@return GenerationResults
function GenerationResults.new(generation, speciesResults)
    local generationResults = {}

    generationResults.generation = generation
    ---@type SpeciesResults[]
    generationResults.speciesResults = speciesResults

    return generationResults
end

---@param pool Pool
---@return GenerationResults
function GenerationResults.create(pool)
    ---@type SpeciesResults[]
    local speciesResults = {}

    for i, species in pairs(pool.species) do
        local topFitness = 0
        local totalFitness = 0
        for _, genome in pairs(species.genomes) do
            if genome.fitness > topFitness then
                topFitness = genome.fitness
            end

            totalFitness = totalFitness + genome.fitness
        end

        local averageFitness = totalFitness / (#species.genomes)
        speciesResults[i] = SpeciesResults.new(#species.genomes, topFitness, totalFitness, averageFitness)
    end

    table.sort(speciesResults, function(a, b)
        return a.topFitness > b.topFitness
    end)

    return GenerationResults.new(pool.generation, speciesResults)
end

return GenerationResults
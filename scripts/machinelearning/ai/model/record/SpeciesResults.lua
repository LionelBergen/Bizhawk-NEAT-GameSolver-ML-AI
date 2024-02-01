---@class SpeciesResults
local SpeciesResults = {}

---@param numberOfGenomes number
---@param topFitness number
---@param totalFitness number
---@param averageFitness number
function SpeciesResults.new(numberOfGenomes, topFitness, totalFitness, averageFitness)
    local speciesResults = {}

    speciesResults.numberOfGenomes = numberOfGenomes
    speciesResults.topFitness = topFitness
    speciesResults.totalFitness = totalFitness
    speciesResults.averageFitness = averageFitness

    return speciesResults
end

return SpeciesResults
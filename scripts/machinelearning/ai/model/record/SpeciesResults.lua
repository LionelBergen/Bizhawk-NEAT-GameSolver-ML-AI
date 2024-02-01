---@class SpeciesResults
local SpeciesResults = {}

---@param topFitness number
---@param totalFitness number
function SpeciesResults.new(topFitness, totalFitness)
    local speciesResults = {}

    speciesResults.topFitness = topFitness
    speciesResults.totalFitness = totalFitness

    return speciesResults
end

return SpeciesResults
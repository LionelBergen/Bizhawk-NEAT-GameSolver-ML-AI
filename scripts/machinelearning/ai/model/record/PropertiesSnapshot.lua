---@class PropertiesSnapshot
local PropertiesSnapshot = {}

local Properties = require('machinelearning.ai.static.Properties')

---@return PropertiesSnapshot
function PropertiesSnapshot.new()
    local propertiesSnapshot = {}

    return propertiesSnapshot
end

---@param neatMLAI Neat
function PropertiesSnapshot.create(neatMLAI)
    local propertiesSnapshot = PropertiesSnapshot.new()

    propertiesSnapshot.percentageOfTopSpeciesToBreedFrom = neatMLAI.percentageOfTopSpeciesToBreedFrom
    propertiesSnapshot.percentageToBreedFromTopSpecies = neatMLAI.percentageToBreedFromTopSpecies
    propertiesSnapshot.mutateConnectionsChance = neatMLAI.mutateConnectionsChance
    propertiesSnapshot.linkMutationChance = neatMLAI.linkMutationChance
    propertiesSnapshot.biasMutationChance = neatMLAI.biasMutationChance
    propertiesSnapshot.nodeMutationChance = neatMLAI.nodeMutationChance
    propertiesSnapshot.enableMutationChance = neatMLAI.enableMutationChance
    propertiesSnapshot.disableMutationChance = neatMLAI.disableMutationChance
    propertiesSnapshot.perturbChance = neatMLAI.perturbChance
    propertiesSnapshot.crossoverChance = neatMLAI.crossoverChance
    propertiesSnapshot.staleSpecies = neatMLAI.staleSpecies
    propertiesSnapshot.stepSize = neatMLAI.stepSize
    propertiesSnapshot.generationStartingPopulation = neatMLAI.population

    propertiesSnapshot.deltaDisjoint = Properties.deltaDisjoint
    propertiesSnapshot.deltaWeights = Properties.deltaWeights
    propertiesSnapshot.deltaThreshold = Properties.deltaThreshold

    propertiesSnapshot.staleSpecies = Properties.staleSpecies
    propertiesSnapshot.randomMutationFactor1 = Properties.randomMutationFactor1
    propertiesSnapshot.randomMutationFactor2 = Properties.randomMutationFactor2

    return propertiesSnapshot
end

return PropertiesSnapshot
---@class Properties
local Properties = {}

Properties.percentageToBreedFromTopSpecies = 0.30
Properties.percentageOfTopSpeciesToBreedFrom = 0.20

Properties.mutateConnectionsChance = 0.25
Properties.linkMutationChance = 2.0
Properties.biasMutationChance = 0.40
Properties.nodeMutationChance = 0.50
Properties.enableMutationChance = 0.2
Properties.disableMutationChance = 0.4
Properties.stepSize = 0.1
Properties.population = 300
Properties.perturbChance = 0.90
Properties.crossoverChance = 0.75

Properties.deltaDisjoint = 2.0
Properties.deltaWeights = 0.4
Properties.deltaThreshold = 3.0

-- After this many times without a higher 'topFitness' genome in the species, remove the species
Properties.staleSpecies = 1500

-- These are used when generating the rates used in calculations. Just to give a bit more variability
Properties.randomMutationFactor1 = 0.95
Properties.randomMutationFactor2 = 1.05263

return Properties
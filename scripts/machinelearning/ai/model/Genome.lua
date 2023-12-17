local Genome = {}

local MutationRate = require('machinelearning.ai.model.MutationRate')
local Gene = require('machinelearning.ai.model.Gene')

function Genome:new(maxNeuron, mutateConnectionsChance, linkMutationChance, biasMutationChance,
                    nodeMutationChance, enableMutationChance, disableMutationChance, stepSize)
    local genome = {}
    self = self or genome
    self.__index = self
    setmetatable(genome, self)

    genome.genes = {}
    genome.fitness = 0
    genome.adjustedFitness = 0
    genome.network = {}
    genome.maxNeuron = maxNeuron or 0
    genome.globalRank = 0
    genome.mutationRates = MutationRate:new(mutateConnectionsChance, linkMutationChance, biasMutationChance,
            nodeMutationChance, enableMutationChance, disableMutationChance, stepSize)

    return genome
end

function Genome:createCopy(genome)
    -- Create a new genome and copy the genes from the passed genome
    local genomeCopy = self:new()
    for _, gene in pairs(genome.genes) do
        table.insert(genomeCopy.genes, Gene:copy(gene))
    end

    -- TODO: should this copy network?
    genomeCopy.network = {}
    genomeCopy.mutationRates = MutationRate:copy(genomeCopy.mutationRates)

    -- copy the rest of the values
    genomeCopy.fitness = genome.fitness
    genomeCopy.adjustedFitness = genome.adjustedFitness
    genomeCopy.maxNeuron = genome.maxNeuron
    genomeCopy.globalRank = genomeCopy.globalRank

    return genomeCopy
end

return Genome
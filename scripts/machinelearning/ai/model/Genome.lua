---@class Genome
local Genome = {}

local MutationRate = require('machinelearning.ai.model.MutationRate')
local Gene = require('machinelearning.ai.model.Gene')
local Validator = require('util.Validator')

---@return Genome
function Genome:new(maxNeuron, mutateConnectionsChance, linkMutationChance, biasMutationChance,
                    nodeMutationChance, enableMutationChance, disableMutationChance, stepSize)
    ---@type Genome
    local genome = {}
    self = self or genome
    self.__index = self
    setmetatable(genome, self)

    ---@type Gene[]
    genome.genes = {}
    genome.fitness = 0
    ---@type Network
    genome.network = {}
    genome.maxNeuron = maxNeuron or 0
    genome.globalRank = 0
    ---@type MutationRate
    genome.mutationRates = MutationRate:new(mutateConnectionsChance, linkMutationChance, biasMutationChance,
            nodeMutationChance, enableMutationChance, disableMutationChance, stepSize)

    return genome
end

---@param genome Genome
---@return Genome
function Genome.copy(genome)
    -- Create a new genome and copy the genes from the passed genome
    ---@type Genome
    local genomeCopy = Genome:new()
    for _, gene in pairs(genome.genes) do
        local geneCopy = Gene.copy(gene)
        genomeCopy:addGene(geneCopy)
    end

    ---@type Network
    genomeCopy.network = {}
    genomeCopy.mutationRates = MutationRate.copy(genome.mutationRates)

    -- copy the rest of the values
    genomeCopy.fitness = genome.fitness or genomeCopy.fitness
    genomeCopy.maxNeuron = genome.maxNeuron or genomeCopy.maxNeuron
    genomeCopy.globalRank = genome.globalRank or genomeCopy.globalRank

    return genomeCopy
end

---@param gene Gene
function Genome:addGene(gene)
    Validator.validateGene(gene)
    table.insert(self.genes, gene)
end

return Genome
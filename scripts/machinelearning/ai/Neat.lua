---@class Neat
local Neat = {}

local ErrorHandler = require('util.ErrorHandler')
local Pool = require('machinelearning.ai.model.Pool')
local Genome = require('machinelearning.ai.model.Genome')
local Gene = require('machinelearning.ai.model.Gene')
local Neuron = require('machinelearning.ai.model.Neuron')
local Species = require('machinelearning.ai.model.Species')
local Network = require('machinelearning.ai.model.Network')
local NeuronInfo = require('machinelearning.ai.model.NeuronInfo')
local NeuronType = require('machinelearning.ai.model.NeuronType')
local Validator = require('../util/Validator')
local MathUtil = require('util.MathUtil')

local defaultMutateConnectionsChance = 0.25
local defaultLinkMutationChance = 2.0
local defaultBiasMutationChance = 0.40
local defaultNodeMutationChance = 0.50
local defaultEnableMutationChance = 0.2
local defaultDisableMutationChance = 0.4
local defaultStepSize = 0.1
local defaultPopulation = 300
local defaultPerturbChance = 0.90

local deltaDisjoint = 2.0
local deltaWeights = 0.4
local deltaThreshold = 1.0

local crossoverChance = 0.75
local staleSpecies = 15

-- Generates a random number between -2 and 2
local function generateRandomWeight()
    return MathUtil.random() * 4 - 2
end

-- Counts the number of non-matching innovation's in genes1 and genes2 then divides by
-- the number of genes of genes1 or genes2, whichever is greater
---@param genes1 Gene[]
---@param genes2 Gene[]
local function disjoint(genes1, genes2)
    local i1 = {}
    local i2 = {}
    local numberrOfDisjointGenes = 0

    for _, gene1 in pairs(genes1) do
        i1[gene1.innovation] = true
    end

    for _, gene2 in pairs(genes2) do
        i2[gene2.innovation] = true
    end

    -- for every gene2 that's not gene1, increment disjointGenes
    for _, gene1 in pairs(genes1) do
        if not i2[gene1.innovation] then
            numberrOfDisjointGenes = numberrOfDisjointGenes + 1
        end
    end

    -- for every gene2 that's not gene1, increment disjointGenes
    for _, gene2 in pairs(genes2) do
        if not i1[gene2.innovation] then
            numberrOfDisjointGenes = numberrOfDisjointGenes + 1
        end
    end

    local numberOfGenes = math.max(#genes1, #genes2)

    return numberrOfDisjointGenes / numberOfGenes
end

-- Returns the average difference between genes1 and genes2 weights
---@param genes1 Gene[]
---@param genes2 Gene[]
local function weights(genes1, genes2)
    local i2 = {}
    local sum = 0
    local coincident = 0

    for _, gene2 in pairs(genes2) do
        i2[gene2.innovation] = gene2
    end

    for _, gene1 in pairs(genes1) do
        if i2[gene1.innovation] ~= nil then
            local gene2 = i2[gene1.innovation]
            sum = sum + math.abs(gene1.weight - gene2.weight)
            coincident = coincident + 1
        end
    end

    return sum / coincident
end

---@param genome1 Genome
---@param genome2 Genome
local function isSameSpecies(genome1, genome2)
    -- Number of matching genes divided by number of genes
    local dd = deltaDisjoint * disjoint(genome1.genes, genome2.genes)
    -- average difference between genes
    local dw = deltaWeights * weights(genome1.genes, genome2.genes)

    return dd + dw < deltaThreshold
end

---@param speciesList Species[]
---@return number
local function calculateTotalFitness(speciesList)
    local totalFitness = 0

    for _, species in pairs(speciesList) do
        for _, genome in pairs(species.genomes) do
            totalFitness = totalFitness + genome.fitness
        end
    end

    return totalFitness
end

---@param pool Pool
local function getTotalAverageFitnessRank(pool)
    local totalRank = 0

    for _, species in pairs(pool.species) do
        totalRank = totalRank + species.averageFitnessRank
    end

    return totalRank
end

---@param genome Genome
local function pointMutate(genome, perturbChance)
    local step = genome.mutationRates.values.step

    for _, gene in pairs(genome.genes) do
        if MathUtil.random() < perturbChance then
            -- Generate a random number between -step and step
            local randomPerturbation = (MathUtil.random() * 2 * step) - step
            gene.weight = gene.weight + randomPerturbation
        else
            gene.weight = generateRandomWeight()
        end
    end

    return genome
end

---@param genes Gene[]
---@return NeuronInfo
local function getRandomNeuronInfo(genes, isInput, inputSizeWithoutBiasNode, outputSize)
    local neurons = {}

    -- Add input Neurons if applicable
    if isInput then
        for i=1,inputSizeWithoutBiasNode do
            neurons[i] = NeuronInfo.new(i, NeuronType.INPUT)
        end

        neurons[#neurons + 1] = NeuronInfo.new(1, NeuronInfo.BIAS)
    end

    -- Add output neurons
    for i=1, outputSize do
        neurons[#neurons + 1] = NeuronInfo.new(i, NeuronType.OUTPUT)
    end

    -- Add neurons from Genes
    for i=1, #genes do
        if isInput or genes[i].into.type ~= NeuronType.INPUT then
            neurons[#neurons + 1] = NeuronInfo.new(genes[i].into.index, genes[i].into.type)
        end
        if isInput or genes[i].out.type ~= NeuronType.INPUT then
            neurons[#neurons + 1] = NeuronInfo.new(genes[i].out.index, genes[i].out.type)
        end
    end

    local randomIndex = MathUtil.random(1, #neurons)
    return neurons[randomIndex]
end

---@param genes Gene[]
---@param link Gene
local function containsLink(genes, link)
    for _, gene in pairs(genes) do
        if (gene.into.index == link.into.index) and (gene.into.type == link.into.type)
                and (gene.out.index == link.out.index) and (gene.out.type == link.out.type) then
            return true
        end
    end

    return false
end

-- Creates a link between two randomly selected neurons.
---@param genome Genome
---@param forceBias boolean
---@param inputSizeWithoutBiasNode number
---@param numberOfOutputs number
---@param pool Pool
---@return Gene
local function linkMutate(genome, forceBias, inputSizeWithoutBiasNode, numberOfOutputs, pool)
    ---@type NeuronInfo
    local sourceNeuronInfo = getRandomNeuronInfo(genome.genes, true, inputSizeWithoutBiasNode, numberOfOutputs)
    ---@type NeuronInfo
    local targetNeuronInfo = getRandomNeuronInfo(genome.genes, false, inputSizeWithoutBiasNode, numberOfOutputs)
    ---@type Gene
    local newLink = Gene.new()

    -- Ensure connections between input nodes are not mutated
    if sourceNeuronInfo.type == NeuronType.INPUT and targetNeuronInfo.type == NeuronType.INPUT then
        -- Both input nodes
        return
    end

    if targetNeuronInfo.type == NeuronType.INPUT then
        -- Swap output and input
        local temp = sourceNeuronInfo
        sourceNeuronInfo = targetNeuronInfo
        targetNeuronInfo = temp
    end

    newLink.into = sourceNeuronInfo
    newLink.out = targetNeuronInfo
    if forceBias then
        newLink.into = NeuronInfo.new(1, NeuronType.BIAS)
    end

    if containsLink(genome.genes, newLink) then
        return
    end

    newLink.innovation = pool:newInnovation()
    newLink.weight = generateRandomWeight()

    return newLink
end

---@return Neat
function Neat:new(mutateConnectionsChance, linkMutationChance, biasMutationChance, nodeMutationChance,
                  enableMutationChance, disableMutationChance, perturbChance, stepSize, population)
    ---@type Neat
    local o = {}
    self = self or o
    self.__index = self
    setmetatable(o, self)

    o.mutateConnectionsChance = mutateConnectionsChance or defaultMutateConnectionsChance
    o.linkMutationChance = linkMutationChance or defaultLinkMutationChance
    o.biasMutationChance = biasMutationChance or defaultBiasMutationChance
    o.nodeMutationChance = nodeMutationChance or defaultNodeMutationChance
    o.enableMutationChance = enableMutationChance or defaultEnableMutationChance
    o.disableMutationChance = disableMutationChance or defaultDisableMutationChance
    o.perturbChance = perturbChance or defaultPerturbChance
    o.stepSize = stepSize or defaultStepSize
    o.population = population or defaultPopulation
    ---@type Pool
    o.pool = nil
    return o
end

-- innovation number used to track gene.
---@return Pool
function Neat:createNewPool(innovation)
    self.pool = Pool:new(innovation)
    return self.pool
end

---@return Genome
function Neat:createNewGenome(maxNeuron)
    return Genome:new(maxNeuron, self.mutateConnectionsChance, self.linkMutationChance, self.biasMutationChance,
            self.nodeMutationChance, self.enableMutationChance, self.disableMutationChance, self.stepSize)
end

---@return Genome
function Neat:getCurrentGenome()
    return self.pool:getCurrentGenome()
end

---@return Genome
function Neat:createBasicGenome(inputSizeWithoutBiasNode, outputSize)
    ---@type Genome
    local genome = self:createNewGenome(nil)

    self:mutate(genome, inputSizeWithoutBiasNode, outputSize)

    return genome
end

---@param pool Pool
function Neat.calculateAverageFitnessRank(pool)
    for _, species in pairs(pool.species) do
        local speciesTotalGenomeRankings = 0

        for _, genome in pairs(species.genomes) do
            speciesTotalGenomeRankings = speciesTotalGenomeRankings + genome.globalRank
        end

        species.averageFitnessRank = speciesTotalGenomeRankings / #species.genomes
    end
end

---@param genome Genome
function Neat.generateNetwork(genome, numberOfInputs, numberOfOutputs)
    ---@type Network
    local network = Network:new()

    for _=1, numberOfInputs do
        network:addInputNeuron(Neuron.new())
    end

    network:setBiasNeuron(Neuron.new())

    for _=1, numberOfOutputs do
        network:addOutputNeuron(Neuron.new())
    end

    table.sort(genome.genes, function (a,b)
        return (a.out.index < b.out.index)
    end)

    for _, gene in pairs(genome.genes) do
        if gene.enabled then
            ---@type Neuron
            local neuron = network:getOrCreateNeuron(gene.out)
            table.insert(neuron.incoming, gene)

            -- create new neuron to the network if applicable
            network:getOrCreateNeuron(gene.into)
        end
    end

    genome.network = network
end

---@param network Network
---@param inputs MarioInputType[]
---@param outputs string[]
function Neat.evaluateNetwork(network, inputs, outputs)
    network:setAllNeuronValues(inputs)

    local outputValues = {}
    for o, output in pairs(outputs) do
        if network.outputNeurons[o].value > 0 then
            outputValues[output] = true
        else
            outputValues[output] = false
        end
    end

    return outputValues
end

---@param g1 Genome
---@param g2 Genome
---@return Genome
function Neat:crossover(g1, g2)
    ---@type Genome
    local child = self:createNewGenome()
    ---@type Gene[]
    local innovations2 = {}

    -- Make sure g1 is the higher fitness genome
    if g2.fitness > g1.fitness then
        local tempg = g1
        g1 = g2
        g2 = tempg
    end

    for i=1,#g2.genes do
        local gene = g2.genes[i]
        innovations2[gene.innovation] = gene
    end

    for i=1,#g1.genes do
        local gene1 = g1.genes[i]
        local gene2 = innovations2[gene1.innovation]
        if gene2 ~= nil and MathUtil.random(2) == 1 and gene2.enabled then
            table.insert(child.genes, Gene.copy(gene2))
        else
            table.insert(child.genes, Gene.copy(gene1))
        end
    end

    child.maxNeuron = math.max(g1.maxNeuron,g2.maxNeuron)

    for mutation,rate in pairs(g1.mutationRates.values) do
        child.mutationRates.values[mutation] = rate
    end

    return child
end

---@param genome Genome
function Neat:nodeMutate(genome)
    if #genome.genes == 0 then
        return
    end

    -- TODO: always 1
    genome.maxNeuron = genome.network.processingNeurons ~= nil and (#genome.network.processingNeurons + 1) or 1

    local gene = genome.genes[MathUtil.random(1,#genome.genes)]
    if not gene.enabled then
        return
    end
    gene.enabled = false

    local gene1 = Gene.copy(gene)
    gene1.out = NeuronInfo.new(genome.maxNeuron, NeuronType.PROCESSING)
    gene1.weight = 1.0
    gene1.innovation = self.pool:newInnovation()
    gene1.enabled = true
    genome:addGene(gene1)

    local gene2 = Gene.copy(gene)
    gene2.into = NeuronInfo.new(genome.maxNeuron, NeuronType.PROCESSING)
    gene2.innovation = self.pool:newInnovation()
    gene2.enabled = true
    genome:addGene(gene2)
end

---@param genome Genome
function Neat.enableDisableMutate(genome, enable)
    local candidates = {}
    for _,gene in pairs(genome.genes) do
        if gene.enabled == not enable then
            table.insert(candidates, gene)
        end
    end

    if #candidates == 0 then
        return
    end

    local gene = candidates[MathUtil.random(1,#candidates)]
    gene.enabled = not gene.enabled
end

---@param genome Genome
function Neat:mutate(genome, inputSizeWithoutBiasNode, numberOfOutputs)
    genome.mutationRates:mutate()
    Validator.validateGenome(genome)

    if MathUtil.random() < genome.mutationRates.values.connections then
        -- modifies gene's weight
        genome = pointMutate(genome, self.perturbChance)
        Validator.validateGenome(genome)
    end

    local p = genome.mutationRates.values.link
    while p > 0 do
        if MathUtil.random() < p then
            ---@type Gene
            local newLink = linkMutate(genome, false, inputSizeWithoutBiasNode, numberOfOutputs, self.pool)
            if newLink ~= nil then
                genome:addGene(newLink)
            end
        end
        p = p - 1
    end

    p = genome.mutationRates.values.bias
    while p > 0 do
        if MathUtil.random() < p then
            local newLink = linkMutate(genome, true, inputSizeWithoutBiasNode, numberOfOutputs, self.pool)
            if newLink ~= nil then
                genome:addGene(newLink)
            end
        end
        p = p - 1
    end

    p = genome.mutationRates.values.node
    while p > 0 do
        if MathUtil.random() < p then
            self:nodeMutate(genome)
        end
        p = p - 1
    end

    p = genome.mutationRates.values.enable
    while p > 0 do
        if MathUtil.random() < p then
            self.enableDisableMutate(genome, true)
        end
        p = p - 1
    end

    p = genome.mutationRates.values.disable
    while p > 0 do
        if MathUtil.random() < p then
            self.enableDisableMutate(genome, false)
        end
        p = p - 1
    end
    Validator.validateGenome(genome)
end

---@param pool Pool
function Neat.rankGlobally(pool)
    local allGenomes = {}
    for _, species in pairs(pool.species) do
        for _, genome in pairs(species.genomes) do
            table.insert(allGenomes, genome)
        end
    end

    -- order from lowest to hightest
    table.sort(allGenomes, function (a,b)
        return (a.fitness < b.fitness)
    end)

    -- set globalRank from lowest fitness to highest
    for g=1, #allGenomes do
        allGenomes[g].globalRank = g
    end
end

---@param pool Pool
---@param cutToOne boolean
function Neat.cullSpecies(pool, cutToOne)
    for _, species in pairs(pool.species) do
        table.sort(species.genomes, function (a,b)
            return (a.fitness > b.fitness)
        end)

        local remaining = cutToOne and 1 or math.ceil(#species.genomes/2)

        while #species.genomes > remaining do
            table.remove(species.genomes)
        end
    end
end

---@param species Species
---@return Genome
function Neat:breedChild(species, numberOfInputs, numberOfOutputs)
    ---@type Genome
    local child
    if MathUtil.random() < crossoverChance then
        local g1 = species.genomes[MathUtil.random(1, #species.genomes)]
        local g2 = species.genomes[MathUtil.random(1, #species.genomes)]
        child = self:crossover(g1, g2)
    else
        local g = species.genomes[MathUtil.random(1, #species.genomes)]
        child = Genome.copy(g)
    end

    self:mutate(child, numberOfInputs, numberOfOutputs)

    return child
end

---@param pool Pool
function Neat.removeStaleSpecies(pool)
    ---@type Species[]
    local survived = {}

    for _, species in pairs(pool.species) do
        -- Sort the table from highest to lowest
        table.sort(species.genomes, function (a,b)
            return (a.fitness > b.fitness)
        end)

         -- Use first element, as its now the one with the highest fitness
        if species.genomes[1].fitness > species.topFitness then
            species.topFitness = species.genomes[1].fitness
            species.staleness = 0

            if species.genomes[1].fitness > pool.maxFitness then
                pool.maxFitness = species.genomes[1].fitness
            end
        else
            species.staleness = species.staleness + 1
        end

        if species.staleness < staleSpecies or species.genomes[1].fitness >= pool.maxFitness then
            table.insert(survived, species)
        end
    end

    pool.species = survived
end

---@param pool Pool
function Neat.removeWeakSpecies(pool)
    ---@type Species[]
    local survived = {}

    local totalAverageFitnessRanks = getTotalAverageFitnessRank(pool)
    for _, species in pairs(pool.species) do
        local breed = math.floor((species.averageFitnessRank / totalAverageFitnessRanks) * pool:getNumberOfGenomes())
        if breed >= 1 then
            table.insert(survived, species)
        end
    end

    pool.species = survived
end

---@param child Genome
function Neat:addToSpecies(child)
    local speciesFound = false

    for _, species in pairs(self.pool.species) do
        -- Because we are combining species that are the same, we just need to check the first one as they all match
        if isSameSpecies(child, species.genomes[1]) then
            table.insert(species.genomes, child)
            speciesFound = true
            break
        end
    end

    if not speciesFound then
        local childSpecies = Species.new()
        table.insert(childSpecies.genomes, child)
        table.insert(self.pool.species, childSpecies)
    end
end

function Neat:newGeneration(numberOfInputs, numberOfOutputs)
    local pool = self.pool

    if pool.species == nil then
        ErrorHandler.error("pool.species was nil")
    end

    -- Destroy the bottom half Genomes of each species
    self.cullSpecies(pool, false)

    -- Destroy any stale Species
    self.removeStaleSpecies(pool)

    -- set each individual Genome.globalRank
    self.rankGlobally(pool)

    -- sets the species.averageFitnessRank for each species
    -- Higher fitnessRank number = better fitness
    self.calculateAverageFitnessRank(pool)

    -- Remove species with a really low averageFitnessRank
    self.removeWeakSpecies(pool)

    local totalAverageFitnessRank = getTotalAverageFitnessRank(pool)

    ---@type Genome[]
    local children = {}
    for _, species in pairs(pool.species) do
        local breed = math.floor((species.averageFitnessRank / totalAverageFitnessRank) * self.population) - 1
        for _=1, breed do
            table.insert(children, self:breedChild(species, numberOfInputs, numberOfOutputs))
        end
    end

    -- Remove all but the top genome of each species
    self.cullSpecies(pool, true)

    while (#children + #pool.species) < self.population do
        local species = pool.species[MathUtil.random(1, #pool.species)]
        table.insert(children, self:breedChild(species, numberOfInputs, numberOfOutputs))
    end

    for _, childGenome in pairs(children) do
        self:addToSpecies(childGenome)
    end

    pool.generation = pool.generation + 1
end

function Neat:initializePool(inputSizeWithoutBiasNode, numberOfOutputs)
    self.pool = self:createNewPool(1)
    Validator.validatePool(self.pool)

    for _=1, self.population do
        local basic = self:createBasicGenome(inputSizeWithoutBiasNode, numberOfOutputs)
        self:addToSpecies(basic)
    end
end

return Neat
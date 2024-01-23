---@class Neat
local Neat = {}

local Pool = require('machinelearning.ai.model.Pool')
local Genome = require('machinelearning.ai.model.Genome')
local Gene = require('machinelearning.ai.model.Gene')
local Neuron = require('machinelearning.ai.model.Neuron')
local Species = require('machinelearning.ai.model.Species')
local Network = require('machinelearning.ai.model.Network')
local NeuronInfo = require('machinelearning.ai.model.NeuronInfo')
local NeuronType = require('machinelearning.ai.model.NeuronType')
local Logger = require('util.Logger')
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

function Neat:newInnovation()
    self.pool.innovation = self.pool.innovation + 1
    return self.pool.innovation
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

    for i=1,#genome.genes do
        local gene = genome.genes[i]
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
function Neat.evaluateNetwork(network, inputs, outputs)
    -- set the input values
    network:setInputValues(inputs)
    network.biasNeuron.value = 1

    for _,neuron in pairs(network:getAllNeurons()) do
        local sum = 0
        for j = 1,#neuron.incoming do
            local incoming = neuron.incoming[j]
            local other = network:getOrCreateNeuron(incoming.into)
            sum = sum + incoming.weight * other.value
        end

        if #neuron.incoming > 0 then
            neuron.value = MathUtil.sigmoid(sum)
        end
    end

    local newOutputs = {}
    for o=1, #outputs do
        local output = outputs[o]
        -- TODO: "P1 " is related to controller in BizHawk. Maybe we should convert it outside this method
        local newOutput = "P1 " .. output
        if network.outputNeurons[o].value > 0 then
            newOutputs[newOutput] = true
        else
            newOutputs[newOutput] = false
        end
    end

    return newOutputs
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

---@param genes Gene[]
---@return NeuronInfo
function Neat.getRandomNeuronInfo(genes, isInput, inputSizeWithoutBiasNode, outputSize)
    local neurons = {}

    -- Add input Neurons if applicable
    if isInput then
        for i=1,inputSizeWithoutBiasNode do
            neurons[i] = NeuronInfo.new(i, NeuronType.INPUT)
        end

        if #neurons >= 170 then
            error(#neurons)
        end

        neurons[#neurons + 1] = NeuronInfo.new(1, NeuronInfo.BIAS)
    end

    -- Add output neurons
    for i=1,outputSize do
        neurons[#neurons + 1] = NeuronInfo.new(i, NeuronType.OUTPUT)
    end

    -- Add neurons from Genes
    for i=1,#genes do
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

-- TODO: Should have a method equals() inside Gene
---@param genes Gene[]
---@param link Gene
function Neat.containsLink(genes, link)
    for i=1,#genes do
        local gene = genes[i]
        if gene.into.index == link.into.index and gene.into.type == link.into.type
                and gene.out.index == link.out.index and gene.out.type == link.out.type then
            return true
        end
    end
end

---@param genome Genome
function Neat:linkMutate(genome, forceBias, inputSizeWithoutBiasNode, numberOfOutputs)
    Validator.validateGenome(genome)
    ---@type NeuronInfo
    local sourceNeuronInfo = self.getRandomNeuronInfo(genome.genes, true, inputSizeWithoutBiasNode, numberOfOutputs)
    ---@type NeuronInfo
    local targetNeuronInfo = self.getRandomNeuronInfo(genome.genes, false, inputSizeWithoutBiasNode, numberOfOutputs)
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

    if self.containsLink(genome.genes, newLink) then
        return
    end

    newLink.innovation = self:newInnovation()
    newLink.weight = generateRandomWeight()

    genome:addGene(newLink)
    Validator.validateGenome(genome)
end

---@param genome Genome
function Neat:nodeMutate(genome)
    if #genome.genes == 0 then
        return
    end

    genome.maxNeuron = genome.network.processingNeurons ~= nil and (#genome.network.processingNeurons + 1) or 1

    if genome.maxNeuron ~= 1 then
        Logger.info('max neuron set to: ' .. genome.maxNeuron)
    end

    local gene = genome.genes[MathUtil.random(1,#genome.genes)]
    if not gene.enabled then
        return
    end
    gene.enabled = false

    local gene1 = Gene.copy(gene)
    gene1.out = NeuronInfo.new(genome.maxNeuron, NeuronType.PROCESSING)
    gene1.weight = 1.0
    gene1.innovation = self:newInnovation()
    gene1.enabled = true
    genome:addGene(gene1)

    local gene2 = Gene.copy(gene)
    gene2.into = NeuronInfo.new(genome.maxNeuron, NeuronType.PROCESSING)
    gene2.innovation = self:newInnovation()
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
        genome = pointMutate(genome, self.perturbChance)
        Validator.validateGenome(genome)
    end

    local p = genome.mutationRates.values.link
    while p > 0 do
        if MathUtil.random() < p then
            self:linkMutate(genome, false, inputSizeWithoutBiasNode, numberOfOutputs)
        end
        p = p - 1
    end

    p = genome.mutationRates.values.bias
    while p > 0 do
        if MathUtil.random() < p then
            self:linkMutate(genome, true, inputSizeWithoutBiasNode, numberOfOutputs)
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

-- TODO: This method doesn't do anything
---@param pool Pool
function Neat.rankGlobally(pool)
    local global = {}
    for s = 1,#pool.species do
        local species = pool.species[s]
        for g = 1,#species.genomes do
            table.insert(global, species.genomes[g])
        end
    end
    table.sort(global, function (a,b)
        return (a.fitness < b.fitness)
    end)

    for g=1,#global do
        global[g].globalRank = g
    end
end

---@param species Species
function Neat.calculateAverageFitness(species)
    local total = 0

    for g=1,#species.genomes do
        local genome = species.genomes[g]
        total = total + genome.globalRank
    end

    species.averageFitness = total / #species.genomes
end

---@param pool Pool
function Neat.totalAverageFitness(pool)
    local total = 0

    if pool.species == nil then
        error("pool.species was nil")
    end


    for s = 1,#pool.species do
        local species = pool.species[s]
        total = total + species.averageFitness
    end

    return total
end

---@param pool Pool
function Neat.cullSpecies(pool, cutToOne)
    for s = 1,#pool.species do
        local species = pool.species[s]

        table.sort(species.genomes, function (a,b)
            return (a.fitness > b.fitness)
        end)

        local remaining = math.ceil(#species.genomes/2)
        if cutToOne then
            remaining = 1
        end
        while #species.genomes > remaining do
            table.remove(species.genomes)
        end
    end
end

---@param species Species
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

    for s = 1,#pool.species do
        local species = pool.species[s]

        table.sort(species.genomes, function (a,b)
            return (a.fitness > b.fitness)
        end)

        if species.genomes[1].fitness > species.topFitness then
            species.topFitness = species.genomes[1].fitness
            species.staleness = 0
        else
            species.staleness = species.staleness + 1
        end
        if species.staleness < staleSpecies or species.topFitness >= pool.maxFitness then
            table.insert(survived, species)
        end
    end

    pool.species = survived
end

function Neat:removeWeakSpecies()
    ---@type Species[]
    local survived = {}
    ---@type Pool
    local pool = self.pool

    if pool.species == nil then
        error("pool.species was nil")
    end

    local sum = self.totalAverageFitness(pool)
    for s = 1,#pool.species do
        local species = pool.species[s]
        local breed = math.floor(species.averageFitness / sum * self.population)
        if breed >= 1 then
            table.insert(survived, species)
        end
    end

    pool.species = survived
end

-- TODO: What is the '1' in species.genomes[1]?
---@param child Genome
function Neat:addToSpecies(child)
    local speciesFound = false

    for _, species in pairs(self.pool.species) do
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
    if self.pool.species == nil then
        error("pool.species was nil")
    end

    local pool = self.pool

    if pool.species == nil then
        error("pool.species was nil")
    end

    -- Cull the bottom half of each species
    self.cullSpecies(pool, false)

    self.rankGlobally(pool)
    self.removeStaleSpecies(pool)
    self.rankGlobally(pool)

    for s = 1,#pool.species do
        local species = pool.species[s]
        self.calculateAverageFitness(species)
    end

    if pool.species == nil then
        error("pool.species was nil")
    end

    self:removeWeakSpecies()

    if pool.species == nil then
        error("pool.species was nil")
    end

    local sum = self.totalAverageFitness(pool)
    local children = {}
    for s = 1,#pool.species do
        local species = pool.species[s]
        local breed = math.floor(species.averageFitness / sum * self.population) - 1
        for _=1,breed do
            table.insert(children, self:breedChild(species, numberOfInputs, numberOfOutputs))
        end
    end
    self.cullSpecies(pool, true) -- Cull all but the top member of each species
    while #children + #pool.species < self.population do
        local species = pool.species[MathUtil.random(1, #pool.species)]
        table.insert(children, self:breedChild(species, numberOfInputs, numberOfOutputs))
    end
    for c=1,#children do
        local child = children[c]
        self:addToSpecies(child)
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
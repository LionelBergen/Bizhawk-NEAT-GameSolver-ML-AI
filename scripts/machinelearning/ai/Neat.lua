---@class Neat
local Neat = {}

local ErrorHandler = require('util.ErrorHandler')
local Logger = require('util.Logger')
local Properties = require('machinelearning.ai.static.Properties')
local Pool = require('machinelearning.ai.model.Pool')
local Genome = require('machinelearning.ai.model.Genome')
local Gene = require('machinelearning.ai.model.Gene')
local Neuron = require('machinelearning.ai.model.Neuron')
local Species = require('machinelearning.ai.model.Species')
local Network = require('machinelearning.ai.model.Network')
local NeuronInfo = require('machinelearning.ai.model.NeuronInfo')
local NeuronType = require('machinelearning.ai.model.NeuronType')
local Validator = require('util.Validator')
local MathUtil = require('util.MathUtil')
local GenomeUtil = require('util.GenomeUtil')
local MutationRate = require('machinelearning.ai.model.MutationRate')

-- Creates a link between two randomly selected neurons.
---@param genome Genome
---@param forceBias boolean
---@param inputSizeWithoutBiasNode number
---@param numberOfOutputs number
---@param pool Pool
---@return Gene
local function linkMutate(genome, forceBias, inputSizeWithoutBiasNode, numberOfOutputs, pool)
    ---@type NeuronInfo
    local sourceNeuronInfo = GenomeUtil.getRandomNeuronInfo(genome.genes, true,
            inputSizeWithoutBiasNode, numberOfOutputs)
    ---@type NeuronInfo
    local targetNeuronInfo = GenomeUtil.getRandomNeuronInfo(genome.genes, false,
            inputSizeWithoutBiasNode, numberOfOutputs)
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

    if GenomeUtil.containsLink(genome.genes, newLink) then
        return
    end

    newLink.innovation = pool:newInnovation()
    newLink.weight = GenomeUtil.generateRandomWeight()

    return newLink
end

---@return Neat
function Neat:new(percentageOfTopSpeciesToBreedFrom, percentageToBreedFromTopSpecies, mutateConnectionsChance,
                  linkMutationChance, biasMutationChance, nodeMutationChance, enableMutationChance,
                  disableMutationChance, perturbChance, crossoverChance, staleSpecies, stepSize, population)
    ---@type Neat
    local o = {}
    self = self or o
    self.__index = self
    setmetatable(o, self)

    o.percentageOfTopSpeciesToBreedFrom = percentageOfTopSpeciesToBreedFrom
            or Properties.percentageOfTopSpeciesToBreedFrom
    o.percentageToBreedFromTopSpecies = percentageToBreedFromTopSpecies or Properties.percentageToBreedFromTopSpecies
    o.mutateConnectionsChance = mutateConnectionsChance or Properties.mutateConnectionsChance
    o.linkMutationChance = linkMutationChance or Properties.linkMutationChance
    o.biasMutationChance = biasMutationChance or Properties.biasMutationChance
    o.nodeMutationChance = nodeMutationChance or Properties.nodeMutationChance
    o.enableMutationChance = enableMutationChance or Properties.enableMutationChance
    o.disableMutationChance = disableMutationChance or Properties.disableMutationChance
    o.perturbChance = perturbChance or Properties.perturbChance
    o.crossoverChance = crossoverChance or Properties.crossoverChance
    o.staleSpecies = staleSpecies or Properties.staleSpecies
    o.stepSize = stepSize or Properties.stepSize
    o.generationStartingPopulation = population or Properties.population
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
function Neat:createNewGenome()
    return Genome:new(nil, self.mutateConnectionsChance, self.linkMutationChance, self.biasMutationChance,
            self.nodeMutationChance, self.enableMutationChance, self.disableMutationChance, self.stepSize)
end

---@return Genome
function Neat:getCurrentGenome()
    return self.pool:getCurrentGenome()
end

---@return Genome
function Neat:createBasicGenome(inputSizeWithoutBiasNode, outputSize)
    ---@type Genome
    local genome = self:createNewGenome()

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

---@param pool Pool
function Neat:orderSpeciesFromBestToWorst(pool)
    -- Sort species based on average fitness rank
    table.sort(pool.species, function(a, b)
        return self.getCalculatedTopFitness(a) > self.getCalculatedTopFitness(b)
    end)
end

---@param species Species
function Neat.getCalculatedTopFitness(species)
    local topFitness = 0

    for _, genome in pairs(species.genomes) do
        if genome.fitness > topFitness then
            topFitness = genome.fitness
        end
    end

    return topFitness
end

-- TODO: remove isTesting and find another way to test bredFrom
---@param pool Pool
---@return Genome[]
function Neat:breedTopSpecies(pool, numberOfOffSpring, numberOfInputs, numberOfOutputs, isTesting)
    self:orderSpeciesFromBestToWorst(pool)

    local topSpeciesCount = math.ceil(#pool.species * self.percentageOfTopSpeciesToBreedFrom)
    local distribution = MathUtil.distribute(numberOfOffSpring, topSpeciesCount)

    ---@type Genome[]
    local children = {}
    for i = 1, topSpeciesCount do
        local species = pool.species[i]
        local amountToBreed = distribution[i]

        for _=1, amountToBreed do
            local childGenome = self:breedChild(species, numberOfInputs, numberOfOutputs)
            table.insert(children, childGenome)
            Logger.info('bred from species with topfitness: ' .. species.topFitness)
            if isTesting then
               childGenome.bredFrom = i
            end
        end
    end

    return children
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
---@param outputs Button[]
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

    for i=1, #g2.genes do
        local gene = g2.genes[i]
        innovations2[gene.innovation] = gene
    end

    for i=1, #g1.genes do
        local gene1 = g1.genes[i]
        local gene2 = innovations2[gene1.innovation]
        if gene2 ~= nil and gene2.enabled and MathUtil.random(2) == 1 then
            table.insert(child.genes, Gene.copy(gene2))
        else
            table.insert(child.genes, Gene.copy(gene1))
        end
    end

    child.maxNeuron = math.max(g1.maxNeuron, g2.maxNeuron)
    child.mutationRates = MutationRate.copy(g1.mutationRates)

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
        genome = GenomeUtil.pointMutate(genome, self.perturbChance)
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

-- Returns rankings from lowest (1) to highest fitness levels and assigns the value to 'globalRank' for each genome
-- Throws an error if the fitness is not set on a genome
---@param pool Pool
function Neat.rankGlobally(pool)
    local allGenomes = {}
    for _, species in pairs(pool.species) do
        for _, genome in pairs(species.genomes) do
            if genome.fitness ~= 0 then
                table.insert(allGenomes, genome)
            else
                ErrorHandler.error('genome does not have fitness set.')
            end
        end
    end

    -- order from lowest to hightest
    table.sort(allGenomes, function (a,b)
        return (a.fitness < b.fitness)
    end)

    local currentRank = 0
    local lastFitnessMeasured

    -- set globalRank from lowest fitness to highest
    for g=1, #allGenomes do
        if (lastFitnessMeasured == nil or allGenomes[g].fitness > lastFitnessMeasured) then
            currentRank = currentRank + 1
            lastFitnessMeasured = allGenomes[g].fitness
        end

        allGenomes[g].globalRank = currentRank
    end
end

-- Destroy's worse genomes based on fitness in all species
---@param pool Pool
---@param cutToOne boolean
function Neat.cullSpecies(pool, cutToOne)
    for _, species in pairs(pool.species) do
        table.sort(species.genomes, function (a, b)
            return (a.fitness > b.fitness)
        end)

        local remaining = cutToOne and 1 or math.ceil(#species.genomes / 2)

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
    if #species.genomes > 1 and MathUtil.random() < self.crossoverChance then
        local g1, g2 = GenomeUtil.getTwoRandomGenomes(species.genomes)
        child = self:crossover(g1, g2)
    else
        local g = GenomeUtil.getGenomeWithHighestFitness(species.genomes)
        child = Genome.copy(g)
    end

    self:mutate(child, numberOfInputs, numberOfOutputs)

    return child
end

---@param pool Pool
function Neat.removeStaleSpecies(pool, staleSpecies)
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
        else
            species.staleness = species.staleness + 1
        end

        if species.staleness < staleSpecies then
            table.insert(survived, species)
        end
    end

    pool.species = survived
end

---@param pool Pool
function Neat.removeWeakSpecies(pool)
    pool.species = GenomeUtil.removeWeakSpecies(pool)
end

---@param child Genome
function Neat:addToSpecies(child)
    local speciesFound = false

    for _, species in pairs(self.pool.species) do
        -- Because we are combining species that are the same, we just need to check the first one as they all match
        if GenomeUtil.isSameSpecies(child, species.genomes[1]) then
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
    local startingPopulation = pool:getNumberOfGenomes()

    if pool.species == nil then
        ErrorHandler.error("pool.species was nil")
    end

    -- Destroy the bottom half Genomes of each species
    self.cullSpecies(pool, false)
    Logger.info('Removed bottom half of species. Went from ' .. startingPopulation
            .. ' genomes down to ' .. pool:getNumberOfGenomes())

    -- Destroy any stale Species
    self.removeStaleSpecies(pool, self.staleSpecies)
    Logger.info('Removed stale species. genomes left: ' .. pool:getNumberOfGenomes())

    -- set each individual Genome.globalRank
    self.rankGlobally(pool)

    -- sets the species.averageFitnessRank for each species
    -- Higher fitnessRank number = better fitness
    self.calculateAverageFitnessRank(pool)

    -- Remove species with a really low averageFitnessRank
    self.removeWeakSpecies(pool)
    Logger.info('Removed weak species. genomes left: ' .. pool:getNumberOfGenomes())

    -- breed 30% with top species
    local numberOfOffSpringWithTopSpecies = (self.generationStartingPopulation - pool:getNumberOfGenomes())
            * self.percentageToBreedFromTopSpecies

    ---@type Genome[]
    local children = self:breedTopSpecies(pool, numberOfOffSpringWithTopSpecies, numberOfInputs, numberOfOutputs)

    Logger.info('Bred ' .. #children .. ' new genomes with top species')

    -- Remove all but the top genome of each species
    self.cullSpecies(pool, true)

    local population = pool:getNumberOfGenomes()
    Logger.info('Removed all but the top genomes. ' .. population
            .. ' genomes are left (not including the children just bred)')
    local numberOfChildrenWithRandomSpecies = 0
    while (#children + population) < self.generationStartingPopulation do
        local species = pool.species[MathUtil.random(1, #pool.species)]
        table.insert(children, self:breedChild(species, numberOfInputs, numberOfOutputs))
        numberOfChildrenWithRandomSpecies = numberOfChildrenWithRandomSpecies + 1
    end
    Logger.info('Bred ' .. numberOfChildrenWithRandomSpecies .. ' new genomes with random species')

    for _, childGenome in pairs(children) do
        self:addToSpecies(childGenome)
    end

    pool.generation = pool.generation + 1
end

function Neat:resetFitness()
    -- Reset all the fitness. Don't reset topFitness as its used to remove stale species if they don't get better
    for _, species in pairs(self.pool.species) do
        for _, genome in pairs(species.genomes) do
            genome.fitness = 0
        end
    end
end

function Neat:initializePool(inputSizeWithoutBiasNode, numberOfOutputs)
    self.pool = self:createNewPool(1)
    Validator.validatePool(self.pool)

    for _=1, self.generationStartingPopulation do
        ---@type Genome
        local basic = self:createBasicGenome(inputSizeWithoutBiasNode, numberOfOutputs)
        self:addToSpecies(basic)
    end
end

return Neat
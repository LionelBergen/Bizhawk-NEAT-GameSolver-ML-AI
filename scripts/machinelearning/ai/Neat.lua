local Neat = {}

local Pool = require('machinelearning/ai/Pool')
local Logger = require('util.Logger')

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

local function sigmoid(x)
    return 2 / (1 + math.exp(-4.9 * x)) - 1
end

-- Counts the number of non-matching innovation's in genes1 and genes2 then divides by
-- the number of genes of genes1 or genes2, whichever is greater
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

local function isSameSpecies(genome1, genome2)
    -- Number of matching genes divided by number of genes
    local dd = deltaDisjoint * disjoint(genome1.genes, genome2.genes)
    -- average difference between genes
    local dw = deltaWeights * weights(genome1.genes, genome2.genes)

    return dd + dw < deltaThreshold
end


local function createNewNeuron()
    local neuron = {}
    neuron.incoming = {}
    neuron.value = 0.0

    return neuron
end

local function createNewSpecies()
    local species = {}
    species.topFitness = 0
    species.staleness = 0
    species.genomes = {}
    species.averageFitness = 0

    return species
end

local function createNewGene()
    local gene = {}
    gene.into = 0
    gene.out = 0
    gene.weight = 0.0
    gene.enabled = true
    gene.innovation = 0

    return gene
end

local function copyGene(gene)
    local geneCopy = createNewGene()
    geneCopy.into = gene.into
    geneCopy.out = gene.out
    geneCopy.weight = gene.weight
    geneCopy.enabled = gene.enabled
    geneCopy.innovation = gene.innovation

    return geneCopy
end

-- TODO: Should be a Neat method?
local function pointMutate(genome, perturbChance)
    local step = genome.mutationRates["step"]

    for _, gene in pairs(genome.genes) do
        if math.random() < perturbChance then
            gene.weight = gene.weight + ((math.random() * (step * 2)) - step)
        else
            gene.weight = (math.random() * 4) - 2
        end
    end

    return genome
end

function Neat:new(mutateConnectionsChance, linkMutationChance, biasMutationChance, nodeMutationChance,
                  enableMutationChance, disableMutationChance, perturbChance, stepSize, population)
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
    o.pool = nil
    return o
end

-- innovation number used to track gene.
-- TODO: could be a local function, shouldn't need to access from outside
function Neat:createNewPool(innovation)
    self.pool = Pool:new(innovation)
    return self.pool
end

-- TODO: should be a local function..
function Neat:createNewSpecies()
    return createNewSpecies()
end

-- TODO: local function
function Neat:createNewGene()
    return createNewGene()
end

function Neat:newInnovation()
    self.pool.innovation = self.pool.innovation + 1
    return self.pool.innovation
end

-- TODO: could also be a local function for Genomes
function Neat:createNewGenome(maxNeuron)
    local genome = {}
    genome.genes = {}
    genome.fitness = 0
    genome.adjustedFitness = 0
    genome.network = {}
    genome.maxNeuron = maxNeuron or 0
    genome.globalRank = 0
    genome.mutationRates = {}
    genome.mutationRates["connections"] = self.mutateConnectionsChance
    genome.mutationRates["link"] = self.linkMutationChance
    genome.mutationRates["bias"] = self.biasMutationChance
    genome.mutationRates["node"] = self.nodeMutationChance
    genome.mutationRates["enable"] = self.enableMutationChance
    genome.mutationRates["disable"] = self.disableMutationChance
    genome.mutationRates["step"] = self.stepSize

    return genome
end

function Neat:createCopyGenome(genome)
    -- Create a new genome and copy the genes from the passed genome
    local genomeCopy = self:createNewGenome()
    for _, gene in pairs(genome.genes) do
        table.insert(genomeCopy.genes, copyGene(gene))
    end

    -- copy the rest of the values
    genomeCopy.maxNeuron = genome.maxNeuron
    genomeCopy.mutationRates["connections"] = genome.mutationRates["connections"]
    genomeCopy.mutationRates["link"] = genome.mutationRates["link"]
    genomeCopy.mutationRates["bias"] = genome.mutationRates["bias"]
    genomeCopy.mutationRates["node"] = genome.mutationRates["node"]
    genomeCopy.mutationRates["enable"] = genome.mutationRates["enable"]
    genomeCopy.mutationRates["disable"] = genome.mutationRates["disable"]

    return genomeCopy
end

function Neat:createBasicGenome(inputSize, outputSize, maxNodes)
    local genome = self:createNewGenome(inputSize)

    self:mutate(genome, inputSize, outputSize, maxNodes)

    return genome
end

function Neat.generateNetwork(genome, numberOfInputs, numberOfOutputs, maxNodes)
    local network = {}
    network.neurons = {}

    for i=1,numberOfInputs do
        network.neurons[i] = createNewNeuron()
    end

    for o=1,numberOfOutputs do
        network.neurons[maxNodes+o] = createNewNeuron()
    end

    table.sort(genome.genes, function (a,b)
        return (a.out < b.out)
    end)

    for i=1,#genome.genes do
        local gene = genome.genes[i]
        if gene.enabled then
            if network.neurons[gene.out] == nil then
                network.neurons[gene.out] = createNewNeuron()
            end

            local neuron = network.neurons[gene.out]
            table.insert(neuron.incoming, gene)
            if network.neurons[gene.into] == nil then
                network.neurons[gene.into] = createNewNeuron()
            end
        end
    end

    genome.network = network
end

function Neat.evaluateNetwork(network, inputSize, inputs, outputs, maxNodes)
    table.insert(inputs, 1)

    if #inputs ~= inputSize then
        console.writeline("Incorrect number of neural network inputs.")
        return {}
    end

    for i=1,#inputs do
        network.neurons[i].value = inputs[i]
    end

    for _,neuron in pairs(network.neurons) do
        local sum = 0
        for j = 1,#neuron.incoming do
            local incoming = neuron.incoming[j]
            local other = network.neurons[incoming.into]
            sum = sum + incoming.weight * other.value
        end

        if #neuron.incoming > 0 then
            neuron.value = sigmoid(sum)
        end
    end

    local newOutputs = {}
    for o=1, #outputs do
        local output = outputs[o]
        -- TODO: "P1 " is related to controller in BizHawk. Maybe we should convert it outside this method
        local newOutput = "P1 " .. output
        if network.neurons[maxNodes+o].value > 0 then
            newOutputs[newOutput] = true
        else
            newOutputs[newOutput] = false
        end
    end

    return newOutputs
end

function Neat:crossover(g1, g2)
    local child = self:createNewGenome()
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
        if gene2 ~= nil and math.random(2) == 1 and gene2.enabled then
            table.insert(child.genes, copyGene(gene2))
        else
            table.insert(child.genes, copyGene(gene1))
        end
    end

    child.maxNeuron = math.max(g1.maxNeuron,g2.maxNeuron)

    for mutation,rate in pairs(g1.mutationRates) do
        child.mutationRates[mutation] = rate
    end

    return child
end

function Neat.randomNeuron(genes, isInput, inputSize, outputSize, maxNodes)
    local neurons = {}
    if isInput then
        for i=1,inputSize do
            neurons[i] = true
        end
    end
    for o=1,outputSize do
        neurons[maxNodes+o] = true
    end
    for i=1,#genes do
        if isInput or genes[i].into > inputSize then
            neurons[genes[i].into] = true
        end
        if isInput or genes[i].out > inputSize then
            neurons[genes[i].out] = true
        end
    end

    local count = 0
    for _,_ in pairs(neurons) do
        count = count + 1
    end
    local n = math.random(1, count)

    for k,_ in pairs(neurons) do
        n = n-1
        if n == 0 then
            return k
        end
    end

    return 0
end

function Neat.containsLink(genes, link)
    for i=1,#genes do
        local gene = genes[i]
        if gene.into == link.into and gene.out == link.out then
            return true
        end
    end
end

function Neat:linkMutate(genome, forceBias, numberOfInputs, numberOfOutputs, maxNodes)
    local neuron1 = self.randomNeuron(genome.genes, true, numberOfInputs, numberOfOutputs, maxNodes)
    local neuron2 = self.randomNeuron(genome.genes, false, numberOfInputs, numberOfOutputs, maxNodes)

    local newLink = createNewGene()
    if neuron1 <= numberOfInputs and neuron2 <= numberOfInputs then
        -- Both input nodes
        return
    end
    if neuron2 <= numberOfInputs then
        -- Swap output and input
        local temp = neuron1
        neuron1 = neuron2
        neuron2 = temp
    end

    newLink.into = neuron1
    newLink.out = neuron2
    if forceBias then
        newLink.into = numberOfInputs
    end

    if self.containsLink(genome.genes, newLink) then
        return
    end

    newLink.innovation = self:newInnovation()
    newLink.weight = math.random() * 4 - 2

    table.insert(genome.genes, newLink)
end

function Neat:nodeMutate(genome)
    if #genome.genes == 0 then
        return
    end

    genome.maxNeuron = genome.maxNeuron + 1

    local gene = genome.genes[math.random(1,#genome.genes)]
    if not gene.enabled then
        return
    end
    gene.enabled = false

    local gene1 = copyGene(gene)
    gene1.out = genome.maxNeuron
    gene1.weight = 1.0
    gene1.innovation = self:newInnovation()
    gene1.enabled = true
    table.insert(genome.genes, gene1)

    local gene2 = copyGene(gene)
    gene2.into = genome.maxNeuron
    gene2.innovation = self:newInnovation()
    gene2.enabled = true
    table.insert(genome.genes, gene2)
end

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

    local gene = candidates[math.random(1,#candidates)]
    gene.enabled = not gene.enabled
end

function Neat:mutate(genome, numberOfInputs, numberOfOutputs, maxNodes)
    for mutation,rate in pairs(genome.mutationRates) do
        if math.random(1,2) == 1 then
            genome.mutationRates[mutation] = 0.95 * rate
        else
            genome.mutationRates[mutation] = 1.05263 * rate
        end
    end

    if math.random() < genome.mutationRates["connections"] then
        genome = pointMutate(genome, self.perturbChance)
    end

    local p = genome.mutationRates["link"]
    while p > 0 do
        if math.random() < p then
            self:linkMutate(genome, false, numberOfInputs, numberOfOutputs, maxNodes)
        end
        p = p - 1
    end

    p = genome.mutationRates["bias"]
    while p > 0 do
        if math.random() < p then
            self:linkMutate(genome, true, numberOfInputs, numberOfOutputs, maxNodes)
        end
        p = p - 1
    end

    p = genome.mutationRates["node"]
    while p > 0 do
        if math.random() < p then
            self:nodeMutate(genome)
        end
        p = p - 1
    end

    p = genome.mutationRates["enable"]
    while p > 0 do
        if math.random() < p then
            self.enableDisableMutate(genome, true)
        end
        p = p - 1
    end

    p = genome.mutationRates["disable"]
    while p > 0 do
        if math.random() < p then
            self.enableDisableMutate(genome, false)
        end
        p = p - 1
    end
end

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

function Neat.calculateAverageFitness(species)
    local total = 0

    for g=1,#species.genomes do
        local genome = species.genomes[g]
        total = total + genome.globalRank
    end

    species.averageFitness = total / #species.genomes
end

function Neat:totalAverageFitness(pool)
    Logger.info('pool species: ')
    local total = 0

    if pool.species == nil then
        error("pool.species was nil")
        console.log('error?')
    end


    for s = 1,#pool.species do
        local species = pool.species[s]
        total = total + species.averageFitness
    end

    return total
end

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

function Neat:breedChild(species, numberOfInputs, numberOfOutputs, maxNodes)
    local child
    if math.random() < crossoverChance then
        local g1 = species.genomes[math.random(1, #species.genomes)]
        local g2 = species.genomes[math.random(1, #species.genomes)]
        child = self:crossover(g1, g2)
    else
        local g = species.genomes[math.random(1, #species.genomes)]
        child = self:createCopyGenome(g)
    end

    self:mutate(child, numberOfInputs, numberOfOutputs, maxNodes)

    return child
end

function Neat.removeStaleSpecies(pool)
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
    local survived = {}
    local pool = self.pool

    if pool.species == nil then
        error("pool.species was nil")
    end

    local sum = self:totalAverageFitness(pool)
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
        local childSpecies = createNewSpecies()
        table.insert(childSpecies.genomes, child)
        table.insert(self.pool.species, childSpecies)
    end
end

function Neat:newGeneration(numberOfInputs, numberOfOutputs, maxNodes)
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

    local sum = self:totalAverageFitness(pool)
    local children = {}
    for s = 1,#pool.species do
        local species = pool.species[s]
        local breed = math.floor(species.averageFitness / sum * self.population) - 1
        for _=1,breed do
            table.insert(children, self:breedChild(species, numberOfInputs, numberOfOutputs, maxNodes))
        end
    end
    self.cullSpecies(pool, true) -- Cull all but the top member of each species
    while #children + #pool.species < self.population do
        local species = pool.species[math.random(1, #pool.species)]
        table.insert(children, self:breedChild(species, numberOfInputs, numberOfOutputs, maxNodes))
    end
    for c=1,#children do
        local child = children[c]
        self:addToSpecies(child)
    end

    pool.generation = pool.generation + 1
end

function Neat:initializePool(numberOfInputs, numberOfOutputs, maxNodes)
    local innovation = numberOfOutputs
    self.pool = self:createNewPool(innovation)

    for _=1,self.population do
        local basic = self:createBasicGenome(numberOfInputs, numberOfOutputs, maxNodes)
        self:addToSpecies(basic)
    end
end

return Neat
local Validator = {}
local Logger = require('../util/Logger')
local NeuronType = require('machinelearning.ai.model.NeuronType')

local poolKeys = {'species', 'generation', 'innovation', 'currentSpecies',
                  'currentGenome', 'currentFrame', 'maxFitness'}
local geneKeys = {'into', 'out', 'weight', 'enabled', 'innovation'}
local speciesKeys = {'topFitness', 'staleness', 'averageFitnessRank', 'genomes' }
local genomeKeys = {'genes', 'fitness', 'network', 'maxNeuron', 'globalRank', 'mutationRates'}
local mutationRateKeys = {'connections', 'link', 'bias', 'node', 'enable', 'disable', 'step', 'rates', 'values'}
local mutationKeys = {'connections', 'mutateConnectionsChance', 'link', 'bias', 'node', 'enable', 'disable', 'step'}

local commonAllowedKeys = { '__index' }

local function hasValue(haystack, needle)
    for _, value in ipairs(haystack) do
        if value == needle then
            return true
        end
    end

    return false
end

local function validateObjectKeys(objectToValidate, validKeys, objectName)
    -- Validate that no additional fields exist
    for i, _ in pairs(objectToValidate) do
        if not hasValue(validKeys, i) and not hasValue(commonAllowedKeys, i) then
            Logger.error('Invalid object.key: ' .. objectName .. '.' .. i)
            error('Invalid object.key: ' .. objectName .. '.' .. i)
        end
    end
end

function Validator.validateNumber(number, message)
    message = message or 'invalid number:'
    message = message .. ' ' .. (number or 'nil')
    if (number == nil or type(number) ~= 'number') then
        Logger.error(message)
        error(message)
    end
end

function Validator.validateIsNotNull(value, errorMessage)
    errorMessage = errorMessage or 'val was nil.'
    if value == nil then
        Logger.error(errorMessage)
        error(errorMessage)
    end
end

---@param pool Pool
function Validator.validatePool(pool)
    Validator.validateIsNotNull(pool, 'pool was nil.')
    Validator.validateNumber(pool.generation, 'pool.generation was invalid.')
    Validator.validateNumber(pool.maxFitness, 'pool.maxFitness was invalid.')
    Validator.validateNumber(pool.currentGenome, 'pool.currentGenome was invalid.')
    Validator.validateNumber(pool.currentSpecies, 'pool.currentSpecies was invalid.')
    Validator.validateNumber(pool.currentFrame, 'pool.innovation was invalid.')
    Validator.validateNumber(pool.innovation, 'pool.currentFrame was invalid.')

    Validator.validateIsNotNull(pool.species, 'pool.species was nil.')
    for _,species in pairs(pool.species) do
        Validator.validateSpecies(species)
    end

    validateObjectKeys(pool, poolKeys, 'pool')
end

---@param gene Gene
function Validator.validateGene(gene)
    Validator.validateIsNotNull(gene, 'genome.genes was nil.')

    Validator.validateIsNotNull(gene.into, 'genome.genes.info was nil.')
    Validator.validateIsNotNull(gene.out, 'genome.genes.out was nil.')

    Validator.validateNumber(gene.into.index, 'pool.species.genome.into.index was invalid.')
    Validator.validateNumber(gene.out.index, 'pool.species.genome.out.index was invalid.')
    Validator.validateNumber(gene.weight, 'pool.species.genome.weight was invalid.')
    Validator.validateNumber(gene.innovation, 'pool.species.genome.innovation was invalid.')

    if gene.out.type == NeuronType.INPUT and gene.out.index > 169 then
        Logger.error('input of gene.out too large.')
        error('input too large.')
    end

    if gene.into.type == NeuronType.INPUT and gene.into.index > 169 then
        Logger.error('input of gene.into too large.')
        error('input too large.')
    end

    validateObjectKeys(gene, geneKeys, 'gene')
end

---@param species Species
function Validator.validateSpecies(species)
    Validator.validateNumber(species.topFitness, 'pool.species.topFitness was invalid.')
    Validator.validateNumber(species.staleness, 'pool.species.staleness was invalid.')
    Validator.validateIsNotNull(species.genomes, 'pool.species.genomes was nil.')

    for _,genome in pairs(species.genomes) do
        Validator.validateGenome(genome)
    end

    validateObjectKeys(species, speciesKeys, 'species')
end

---@param genome Genome
function Validator.validateGenome(genome)
    Validator.validateNumber(genome.fitness, 'pool.species.genome.fitness was invalid.')
    Validator.validateNumber(genome.maxNeuron, 'pool.species.genome.maxNeuron was invalid.')
    Validator.validateIsNotNull(genome.mutationRates, 'genome.mutationRates was nil.')

    Validator.validateMutationRates(genome.mutationRates)
    Validator.validateIsNotNull(genome.genes, 'genome.genes was nil.')

    for _,gene in pairs(genome.genes) do
        Validator.validateGene(gene)
    end
    validateObjectKeys(genome, genomeKeys, 'genome')
end

---@param mutationRate MutationRate
function Validator.validateMutationRates(mutationRate)
    Validator.validateIsNotNull(mutationRate, 'genome.mutationRates was nil.')
    Validator.validateIsNotNull(mutationRate.rates, 'genome.mutationRates.Rate was nil.')
    Validator.validateIsNotNull(mutationRate.values, 'genome.mutationRates Values nil.')

    for mutation,rate in pairs(mutationRate.rates) do
        Validator.validateIsNotNull(mutation, 'pool.species.genome.mutationRates.mutation was invalid.')
        Validator.validateNumber(rate, 'pool.species.genome.mutationRates.rates.rate was invalid.')

        Validator.validateIsNotNull(mutationRate.values[mutation],
                'pool.species.genome.mutationRates.mutation was invalid.')
        Validator.validateNumber(mutationRate.values[mutation],
                'pool.species.genome.mutationRates.rates.rate was invalid.')
    end

    validateObjectKeys(mutationRate, mutationRateKeys, 'mutationRate')
    validateObjectKeys(mutationRate.rates, mutationKeys, 'mutation')
end


return Validator
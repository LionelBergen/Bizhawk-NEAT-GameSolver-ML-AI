---@class GenomeUtil
local GenomeUtil = {}

local MathUtil = require('util.MathUtil')
local Properties = require('machinelearning.ai.static.Properties')

local function shuffle(t)
    local s = {}
    for i = 1, #t do s[i] = t[i] end
    for i = #t, 2, -1 do
        local j = MathUtil.random(i)
        s[i], s[j] = s[j], s[i]
    end
    return s
end

-- Counts the number of non-matching innovation's in genes1 and genes2 then divides by
-- the number of genes of genes1 or genes2, whichever is greater
---@param genes1 Gene[]
---@param genes2 Gene[]
local function disjoint(genes1, genes2)
    local i1 = {}
    local i2 = {}
    local numberOfDisjointGenes = 0

    for _, gene1 in pairs(genes1) do
        i1[gene1.innovation] = true
    end

    for _, gene2 in pairs(genes2) do
        i2[gene2.innovation] = true
    end

    -- for every gene2 that's not gene1, increment disjointGenes
    for _, gene1 in pairs(genes1) do
        if not i2[gene1.innovation] then
            numberOfDisjointGenes = numberOfDisjointGenes + 1
        end
    end

    -- for every gene2 that's not gene1, increment disjointGenes
    for _, gene2 in pairs(genes2) do
        if not i1[gene2.innovation] then
            numberOfDisjointGenes = numberOfDisjointGenes + 1
        end
    end

    local numberOfGenes = math.max(#genes1, #genes2)

    return numberOfDisjointGenes / numberOfGenes
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

---@param pool Pool
local function getTotalAverageFitnessRank(pool)
    local totalRank = 0

    for _, species in pairs(pool.species) do
        totalRank = totalRank + species.averageFitnessRank
    end

    return totalRank
end

-- Generates a random number between -2 and 2
function GenomeUtil.generateRandomWeight()
    return MathUtil.random() * 4 - 2
end

---@param genomes Genome[]
---@return Genome, Genome
function GenomeUtil.getTwoRandomGenomes(genomes)
    local shuffledGenomeList = shuffle(genomes)

    return shuffledGenomeList[1], shuffledGenomeList[2]
end

---@param genomes Genome[]
---@return Genome
function GenomeUtil.getGenomeWithHighestFitness(genomes)
    table.sort(genomes, function (a,b)
        return (a.fitness > b.fitness)
    end)

    return genomes[1]
end

---@param genome1 Genome
---@param genome2 Genome
function GenomeUtil.isSameSpecies(genome1, genome2)
    -- Number of matching genes divided by number of genes
    local dd = Properties.deltaDisjoint * disjoint(genome1.genes, genome2.genes)
    -- average difference between genes
    local dw = Properties.deltaWeights * weights(genome1.genes, genome2.genes)

    return dd + dw < Properties.deltaThreshold
end

---@param pool Pool
function GenomeUtil.removeWeakSpecies(pool)
    ---@type Species[]
    local survived = {}

    local totalAverageFitnessRanks = getTotalAverageFitnessRank(pool)
    for _, species in pairs(pool.species) do
        local breed = math.floor((species.averageFitnessRank / totalAverageFitnessRanks) * pool:getNumberOfGenomes())
        if breed >= 1 then
            table.insert(survived, species)
        end
    end

    return survived
end


return GenomeUtil
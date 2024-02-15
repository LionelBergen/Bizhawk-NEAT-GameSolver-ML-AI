---@class GenomeUtil
local GenomeUtil = {}

local MathUtil = require('util.MathUtil')

local function shuffle(t)
    local s = {}
    for i = 1, #t do s[i] = t[i] end
    for i = #t, 2, -1 do
        local j = MathUtil.random(i)
        s[i], s[j] = s[j], s[i]
    end
    return s
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


return GenomeUtil
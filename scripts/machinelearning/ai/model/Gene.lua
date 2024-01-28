---@class Gene
local Gene = {}
local NeuronInfo = require('machinelearning.ai.model.NeuronInfo')

---@return Gene
function Gene.new()
    ---@type Gene
    local gene = {}
    ---@type NeuronInfo
    gene.into = NeuronInfo.new(0)
    ---@type NeuronInfo
    gene.out = NeuronInfo.new(0)
    gene.weight = 0.0
    gene.enabled = true
    gene.innovation = 0

    return gene
end

---@param gene Gene
---@return Gene
function Gene.copy(gene)
    ---@type Gene
    local geneCopy = Gene.new()
    geneCopy.into = NeuronInfo.copy(gene.into)
    geneCopy.out = NeuronInfo.copy(gene.out)
    geneCopy.weight = gene.weight
    geneCopy.enabled = gene.enabled
    geneCopy.innovation = gene.innovation

    return geneCopy
end

return Gene
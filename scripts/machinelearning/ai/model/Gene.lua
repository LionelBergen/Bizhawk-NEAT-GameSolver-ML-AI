---@class Gene
local Gene = {}

---@return Gene
function Gene.new()
    ---@type Gene
    local gene = {}
    gene.into = 0
    gene.out = 0
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
    geneCopy.into = gene.into
    geneCopy.out = gene.out
    geneCopy.weight = gene.weight
    geneCopy.enabled = gene.enabled
    geneCopy.innovation = gene.innovation

    return geneCopy
end

return Gene
local Gene = {}

function Gene:new()
    local gene = {}
    self = self or gene
    self.__index = self
    setmetatable(gene, self)


    gene.into = 0
    gene.out = 0
    gene.weight = 0.0
    gene.enabled = true
    gene.innovation = 0

    return gene
end

function Gene:copy(gene)
    local geneCopy = Gene:new()
    geneCopy.into = gene.into
    geneCopy.out = gene.out
    geneCopy.weight = gene.weight
    geneCopy.enabled = gene.enabled
    geneCopy.innovation = gene.innovation

    return geneCopy
end

return Gene
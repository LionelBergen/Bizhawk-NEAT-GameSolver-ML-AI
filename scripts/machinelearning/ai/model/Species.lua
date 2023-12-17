local Species = {}

function Species.new()
    local species = {}

    species.topFitness = 0
    species.staleness = 0
    species.averageFitness = 0
    species.genomes = {}

    return species
end

return Species
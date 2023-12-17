local MutationRate = {}

local defaultMutateConnectionsChance = 0.25
local defaultLinkMutationChance = 2.0
local defaultBiasMutationChance = 0.40
local defaultNodeMutationChance = 0.50
local defaultEnableMutationChance = 0.2
local defaultDisableMutationChance = 0.4
local defaultStepSize = 0.1

function MutationRate:new(mutateConnectionsChance, linkMutationChance, biasMutationChance, nodeMutationChance,
                          enableMutationChance, disableMutationChance, stepSize)
    local mutationRate = {}
    self = self or mutationRate
    self.__index = self
    setmetatable(mutationRate, self)

    mutationRate.connections = mutateConnectionsChance or defaultMutateConnectionsChance
    mutationRate.link = linkMutationChance or defaultLinkMutationChance
    mutationRate.bias = biasMutationChance or defaultBiasMutationChance
    mutationRate.node = nodeMutationChance or defaultNodeMutationChance
    mutationRate.enable = enableMutationChance or defaultEnableMutationChance
    mutationRate.disable = disableMutationChance or defaultDisableMutationChance
    mutationRate.step = stepSize or defaultStepSize

    return mutationRate
end

function MutationRate:copy(mutationRates)
    local mutationRatesCopy = MutationRate:new()
    mutationRatesCopy.connections = mutationRates.connections
    mutationRatesCopy.link = mutationRates.link
    mutationRatesCopy.bias = mutationRates.bias
    mutationRatesCopy.node = mutationRates.node
    mutationRatesCopy.enable = mutationRates.enable
    mutationRatesCopy.disable = mutationRates.disable
    mutationRatesCopy.step = mutationRates.step

    return mutationRatesCopy
end

return MutationRate
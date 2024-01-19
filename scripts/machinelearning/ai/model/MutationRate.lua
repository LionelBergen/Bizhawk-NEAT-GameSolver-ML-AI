---@class MutationRate
local MutationRate = {}

local Rate = require('machinelearning.ai.model.Rate')
local MathUtil = require('util.MathUtil')

local defaultMutateConnectionsChance = 0.25
local defaultLinkMutationChance = 2.0
local defaultBiasMutationChance = 0.40
local defaultNodeMutationChance = 0.50
local defaultEnableMutationChance = 0.2
local defaultDisableMutationChance = 0.4
local defaultStepSize = 0.1

local defaultMutationAmount1 = 0.95
local defaultMutationAmount2 = 1.05263

---@return MutationRate
function MutationRate:new(mutateConnectionsChance, linkMutationChance, biasMutationChance, nodeMutationChance,
                          enableMutationChance, disableMutationChance, stepSize)
    ---@type MutationRate
    local mutationRate = {}
    self = self or mutationRate
    self.__index = self
    setmetatable(mutationRate, self)

    ---@type Rate
    local rates = Rate.new(mutateConnectionsChance or defaultMutateConnectionsChance,
                          linkMutationChance or defaultLinkMutationChance,
                          biasMutationChance or defaultBiasMutationChance,
                          nodeMutationChance or defaultNodeMutationChance,
                          enableMutationChance or defaultEnableMutationChance,
                          disableMutationChance or defaultDisableMutationChance,
                          stepSize or defaultStepSize)
    local values = {}

    -- will be set after mutate
    values.connections = nil
    values.link = nil
    values.bias = nil
    values.node = nil
    values.enable = nil
    values.disable = nil
    values.step = nil

    mutationRate.rates = rates
    mutationRate.values = values

    return mutationRate
end

---@param mutationRates MutationRate
---@return MutationRate
function MutationRate.copy(mutationRates)
    ---@type MutationRate
    local mutationRatesCopy = MutationRate:new()
    mutationRatesCopy.rates = Rate.copy(mutationRates.rates)
    mutationRatesCopy.values = {}

    mutationRatesCopy.values.connections = mutationRates.values.connections or mutationRatesCopy.values.connections
    mutationRatesCopy.values.link = mutationRates.values.link or mutationRatesCopy.values.link
    mutationRatesCopy.values.bias = mutationRates.values.bias or mutationRatesCopy.values.bias
    mutationRatesCopy.values.node = mutationRates.values.node or mutationRatesCopy.values.node
    mutationRatesCopy.values.enable = mutationRates.values.enable or mutationRatesCopy.values.enable
    mutationRatesCopy.values.disable = mutationRates.values.disable or mutationRatesCopy.values.disable
    mutationRatesCopy.values.step = mutationRates.values.step or mutationRatesCopy.values.step

    return mutationRatesCopy
end

-- Sets the values of self depending on values passed and self.rate
function MutationRate:mutate(amountA, amountB)
    amountA = amountA or defaultMutationAmount1
    amountB = amountB or defaultMutationAmount2
    for key,rate in pairs(self.rates) do
        if MathUtil.random(1,2) == 1 then
            self.values[key] = amountA * rate
        else
            self.values[key] = amountB * rate
        end
    end
end

return MutationRate
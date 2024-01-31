---@class MutationRate
local MutationRate = {}

local Properties = require('machinelearning.ai.static.Properties')
local Rate = require('machinelearning.ai.model.Rate')
local MathUtil = require('util.MathUtil')

---@return MutationRate
function MutationRate:new(mutateConnectionsChance, linkMutationChance, biasMutationChance, nodeMutationChance,
                          enableMutationChance, disableMutationChance, stepSize)
    ---@type MutationRate
    local mutationRate = {}
    self = self or mutationRate
    self.__index = self
    setmetatable(mutationRate, self)

    ---@type Rate
    local rates = Rate.new(mutateConnectionsChance or Properties.mutateConnectionsChance,
                          linkMutationChance or Properties.linkMutationChance,
                          biasMutationChance or Properties.biasMutationChance,
                          nodeMutationChance or Properties.nodeMutationChance,
                          enableMutationChance or Properties.enableMutationChance,
                          disableMutationChance or Properties.disableMutationChance,
                          stepSize or Properties.stepSize)
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
    amountA = amountA or Properties.randomMutationFactor1
    amountB = amountB or Properties.randomMutationFactor2

    -- For better readability, we won't use a for-loop.
    self.values.connections = self.rates.connections * (MathUtil.random(1,2) == 1 and amountA or amountB)
    self.values.link = self.rates.link * (MathUtil.random(1,2) == 1 and amountA or amountB)
    self.values.bias = self.rates.bias * (MathUtil.random(1,2) == 1 and amountA or amountB)
    self.values.node = self.rates.node * (MathUtil.random(1,2) == 1 and amountA or amountB)
    self.values.enable = self.rates.enable * (MathUtil.random(1,2) == 1 and amountA or amountB)
    self.values.disable = self.rates.disable * (MathUtil.random(1,2) == 1 and amountA or amountB)
    self.values.step = self.rates.step * (MathUtil.random(1,2) == 1 and amountA or amountB)

    -- For better readability, we won't use a for-loop.
    --[[
    for key,rate in pairs(self.rates) do
        local amount = MathUtil.random(1,2) == 1 and amountA or amountB

        self.values[key] = amount * rate
    end
    -- ]]
end

return MutationRate
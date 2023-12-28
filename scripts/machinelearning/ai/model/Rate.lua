---@class Rate
local Rate = {}

function Rate.new(mutateConnectionsChance, linkMutationChance, biasMutationChance, nodeMutationChance,
                  enableMutationChance, disableMutationChance, stepSize)
    local rate = {}

    rate.connections = mutateConnectionsChance
    rate.link = linkMutationChance
    rate.bias = biasMutationChance
    rate.node = nodeMutationChance
    rate.enable = enableMutationChance
    rate.disable = disableMutationChance
    rate.step = stepSize

    return rate
end

---@param rate Rate
---@return Rate
function Rate.copy(rate)
    ---@type Rate
    local rateCopy

    if (rate ~= nil) then
        rateCopy = Rate.new()

        rateCopy.connections = rate.connections
        rateCopy.link = rate.link
        rateCopy.bias = rate.bias
        rateCopy.node = rate.node
        rateCopy.enable = rate.enable
        rateCopy.disable = rate.disable
        rateCopy.step = rate.step
    end

    return rateCopy
end

return Rate
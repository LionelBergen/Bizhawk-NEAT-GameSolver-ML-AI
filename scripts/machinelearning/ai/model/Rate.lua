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

        rateCopy.connections = rate.connections or rateCopy.connections
        rateCopy.link = rate.link or rateCopy.link
        rateCopy.bias = rate.bias or rateCopy.bias
        rateCopy.node = rate.node or rateCopy.node
        rateCopy.enable = rate.enable or rateCopy.enable
        rateCopy.disable = rate.disable or rateCopy.disable
        rateCopy.step = rate.step or rateCopy.step
    end

    return rateCopy
end

return Rate
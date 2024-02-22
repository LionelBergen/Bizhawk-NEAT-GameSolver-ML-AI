---@class ControllerTransformer
local ControllerTransformer = {}

local Button = require('machinelearning.ai.model.game.Button')

--- Transforms an array of controller keys to have 'P1 ' prefix.
--- Also prevents both LEFT+RIGHT or UP+DOWN from being true.
--- E.G `A=true,B=false,LEFT=true,RIGHT=true` becomes `P1 A=true,P1 B=false,P1 LEFT=false,P1 RIGHT=false`
---@param networkController Button[]
function ControllerTransformer.transformNetworkOutputs(networkController)
    local newController = {}
    for k, v in pairs(networkController) do
        local newKey = "P1 " .. k

        newController[newKey] = v
    end

    if newController["P1 Left"] and newController["P1 Right"] then
        newController["P1 Left"] = false
        newController["P1 Right"] = false
    end
    if newController["P1 Up"] and newController["P1 Down"] then
        newController["P1 Up"] = false
        newController["P1 Down"] = false
    end

    return newController
end

return ControllerTransformer


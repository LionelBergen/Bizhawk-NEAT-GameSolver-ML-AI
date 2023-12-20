---@class Network
local Network = {}

---@return Network
function Network.new()
    ---@type Network
    local network = {}

    ---@type Neuron[]
    network.neurons = {}

    return network
end

return Network
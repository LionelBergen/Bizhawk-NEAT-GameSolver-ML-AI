---@class Neuron
local Neuron = {}

---@return Neuron
function Neuron.new()
    ---@type Neuron
    local neuron = {}
    ---@type Gene[]
    neuron.incoming = {}
    neuron.value = 0.0

    return neuron
end

return Neuron
local Neuron = {}

function Neuron:new()
    local neuron = {}
    neuron.incoming = {}
    neuron.value = 0.0

    return neuron
end

return Neuron
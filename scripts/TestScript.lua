local FileUtil = require('util/FileUtil')
local GameHandler = require('util/bizhawk/GameHandler')
local Mario = require('Mario')
local Neat = require('machinelearning/ai/Neat')
local Pool = require('machinelearning.ai.Pool')

local MutateConnectionsChance = 0.25
local PerturbChance = 0.90
local CrossoverChance = 0.75
local LinkMutationChance = 2.0
local NodeMutationChance = 0.50
local BiasMutationChance = 0.40
local StepSize = 0.1
local DisableMutationChance = 0.4
local EnableMutationChance = 0.2

local maxNodes = 1000000

-- this is the Programs 'view'
local ProgramViewBoxRadius = 6
local InputSize = (ProgramViewBoxRadius*2+1)*(ProgramViewBoxRadius*2+1)

local ButtonNames = {
    "A",
    "B",
    "X",
    "Y",
    "Up",
    "Down",
    "Left",
    "Right",
}

local numberOfOutputs = #ButtonNames
local numberOfInputs = InputSize

local neatMLAI = Neat:new()
neatMLAI:initializePool(numberOfInputs, numberOfOutputs, maxNodes)

local pool1 = Pool:new()
local pool2 = Pool.new()
local pool3 = Pool:new()

pool3.innovation = 99

print (pool1.innovation)
print (pool2.innovation)
print (pool3.innovation)

print "goodbye world"
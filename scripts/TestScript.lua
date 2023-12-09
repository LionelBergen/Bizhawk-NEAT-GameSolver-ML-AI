local FileUtil = require('util/FileUtil')
local GameHandler = require('util/bizhawk/GameHandler')
local Mario = require('util/bizhawk/rom/MarioRomHandler')
local Neat = require('machinelearning/ai/Neat')

local MutateConnectionsChance = 0.25
local PerturbChance = 0.90
local CrossoverChance = 0.75
local LinkMutationChance = 2.0
local NodeMutationChance = 0.50
local BiasMutationChance = 0.40
local StepSize = 0.1
local DisableMutationChance = 0.4
local EnableMutationChance = 0.2

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

print "goodbye world"
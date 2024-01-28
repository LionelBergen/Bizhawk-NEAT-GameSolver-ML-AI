local GameHandler = {}

local FileUtil = require('../util/FileUtil')
local Logger = require('../util/Logger')
local Validator = require('../util/Validator')
local Pool = require('machinelearning.ai.model.Pool')
local Json = require('../lib/json')

-- luacheck: globals savestate joypad

-- Load a save game from the relative path specified
function GameHandler.loadSavedGame(fileLocation)
	local currentDir = FileUtil.getCurrentDirectory()
	local fullFilePath = currentDir .. "\\" ..fileLocation
	FileUtil.validateFilePath(fullFilePath)

	savestate.load(fullFilePath)
	Logger.debug('loaded save game from file: ' .. fullFilePath)
end

-- Gets the latest pool file, based on the number. E.G 'back.40.restofname.pool'
---@return string, number
function GameHandler.getLatestBackupFile(poolSavesFolder)
	local listOfAllPoolFiles = FileUtil.scandir(poolSavesFolder)
	local latestBackupNumber = -1
	local latestBackupFile

	for _, value in pairs(listOfAllPoolFiles) do
		local res = value.match(value, [[backup.(%d+)]])

		if res ~= nil and latestBackupNumber < tonumber(res) then
			latestBackupNumber = tonumber(res)
			latestBackupFile = value
		end
	end

	return latestBackupFile, latestBackupNumber
end

---@return Pool, any
function GameHandler.loadFromFile(filename, innovation)
	Logger.info('loadfile: ' .. filename)

	local file = io.open(filename, "r")
	local line = file:read()
	local poolFromFile = Json.decode(line)
	file:close()

	---@type Pool
	local pool = Pool.copy(poolFromFile)
	pool.innovation = innovation
	Validator.validatePool(pool)

	return pool, poolFromFile.additionalFields
end

-- Gets info about a pool and saves it to a file
---@param pool Pool
function GameHandler.saveFileFromPool(filename, pool, additionalFields)
	-- before writing to file, validate the pool
	Validator.validatePool(pool)

	local fileJson = io.open(filename, "w")
	-- Create an object that wont have functions
	local rawPool = {}
	rawPool.generation = pool.generation
	rawPool.maxFitness = pool.maxFitness
	rawPool.innovation = pool.innovation

	-- extra fields that dont exist in the class
	rawPool.additionalFields = additionalFields

	rawPool.species = {}
	for i, species in pairs(pool.species) do
		rawPool.species[i] = {}
		rawPool.species[i].topFitness = species.topFitness
		rawPool.species[i].staleness = species.staleness
		rawPool.species[i].genomes = {}

		for j,genome in pairs(species.genomes) do
			rawPool.species[i].genomes[j] = {}
			rawPool.species[i].genomes[j].fitness = genome.fitness
			rawPool.species[i].genomes[j].maxNeuron = genome.maxNeuron
			rawPool.species[i].genomes[j].mutationRates = genome.mutationRates
			rawPool.species[i].genomes[j].genes = {}

			for k,gene in pairs(genome.genes) do
				rawPool.species[i].genomes[j].genes[k] = {}
				rawPool.species[i].genomes[j].genes[k].into = gene.into
				rawPool.species[i].genomes[j].genes[k].out = gene.out
				rawPool.species[i].genomes[j].genes[k].weight = gene.weight
				rawPool.species[i].genomes[j].genes[k].innovation = gene.innovation
				rawPool.species[i].genomes[j].genes[k].enabled = gene.enabled
			end
		end
	end

	fileJson:write(Json.encode(rawPool))
	fileJson:close()
end

function GameHandler.clearJoypad(rom)
	local controller = {}
	for b = 1,#rom.getButtonOutputs() do
		controller["P1 " .. rom.getButtonOutputs()[b]] = false
	end
	joypad.set(controller)
end


return GameHandler
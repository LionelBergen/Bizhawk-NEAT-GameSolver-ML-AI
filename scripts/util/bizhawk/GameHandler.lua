local GameHandler = {}

local FileUtil = require('../util/FileUtil')
local Logger = require('../util/Logger')

-- luacheck: globals savestate

-- Load a save game from the relative path specified
function GameHandler.loadSavedGame(fileLocation)
	local currentDir = FileUtil.getCurrentDirectory()
	local fullFilePath = currentDir .. "\\" ..fileLocation
	FileUtil.validateFilePath(fullFilePath)

	savestate.load(fullFilePath)
	Logger.info('loaded save game from file: ' .. fullFilePath)
end

-- Gets the latest pool file, based on the number. E.G 'back.40.restofname.pool'
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

	return latestBackupFile
end

-- Gets info about a pool and saves it to a file
function GameHandler.saveFileFromPool(filename, pool)
	local file = io.open(filename, "w")
	file:write(pool.generation .. "\n")
	file:write(pool.maxFitness .. "\n")
	file:write(#pool.species .. "\n")

	for _,species in pairs(pool.species) do
		file:write(species.topFitness .. "\n")
		file:write(species.staleness .. "\n")
		file:write(#species.genomes .. "\n")
		for _,genome in pairs(species.genomes) do
			file:write(genome.fitness .. "\n")
			file:write(genome.maxNeuron .. "\n")
			for mutation,rate in pairs(genome.mutationRates) do
				file:write(mutation .. "\n")
				file:write(rate .. "\n")
			end
			file:write("done\n")

			file:write(#genome.genes .. "\n")
			for _,gene in pairs(genome.genes) do
				file:write(gene.into .. " ")
				file:write(gene.out .. " ")
				file:write(gene.weight .. " ")
				file:write(gene.innovation .. " ")
				if(gene.enabled) then
					file:write("1\n")
				else
					file:write("0\n")
				end
			end
		end
	end
	file:close()
end


return GameHandler
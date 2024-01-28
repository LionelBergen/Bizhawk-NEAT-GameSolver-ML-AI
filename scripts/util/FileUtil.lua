---@class FileUtil
local FileUtil = {}

-- ip.popen causes a window to open which can get annoying. So 'cache' the result
local currentDirectory

function FileUtil.getCurrentDirectory()
	if currentDirectory then
		return currentDirectory
	end

	currentDirectory = io.popen"cd":read'*l'
	return currentDirectory
end

function FileUtil.scandir(directory)
	local results = {}
	-- get list of files based on windows command
    local p = io.popen('dir "' .. directory .. '" /b')
	-- iterate through the list of files
    for file in p:lines() do
        table.insert(results, file)
    end
	return results
end

function FileUtil.validateFilePath(fileLocation)
	local fileOpened=io.open(fileLocation, "r")
	if fileOpened~=nil then
		io.close(fileOpened)
	else
		error('save file does not exist!: ' .. fileLocation)
	end
end

function FileUtil.fileExists(filePath)
	local fileHandle = io.open(filePath, "r")

	if fileHandle then
		io.close(fileHandle)
		return true
	else
		return false
	end
end

return FileUtil
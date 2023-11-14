local FileUtil = {}

function FileUtil.getCurrentDirectory()
	return io.popen"cd":read'*l'
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
		console.log('loaded file: ' .. fileLocation)
	else
		error('save file does not exist!: ' .. fileLocation) 
	end
end

return FileUtil
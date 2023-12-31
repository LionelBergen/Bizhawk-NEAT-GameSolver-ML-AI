-- Simple class to wrap 'print' or 'console.log', just to make porting easier
local Logger = {}
local debugFunction = nil

-- luacheck: globals console

local function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"'..k..'"'
            end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

local function print(message)
    console.log(message)
end

function Logger.info(message)
    if type(message) == 'table' then
        local string = dump(message)
        print(string)
    else
        print(message)
    end
end

function Logger.error(message)
    print(debug.traceback())
    if type(message) == 'table' then
        local string = dump(message)
        print(string)
    else
        print(message)
    end
end

function Logger.debug(message)
    if type(message) == 'table' then
        local string = dump(message)
        debugFunction(string)
    else
        debugFunction(message)
        print(message)
    end
end

function Logger.setDebugFunction(newDebugFunction)
    debugFunction = newDebugFunction
end

return Logger
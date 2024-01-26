-- Simple class to wrap 'print' or 'console.log', just to make porting easier
local Logger = {}
local Levels = {
    DEBUG = 1,
    INFO = 2
}
Logger.level = Levels.INFO

local log = require('lib.log')
log.outfile = '../machine_learning_outputs/NEAT_PROGRAM.log'

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
    log.info(message)
end

function Logger.info(message)
    if type(message) == 'table' then
        local string = dump(message)
        print(string)
    else
        print(message)
    end
end

function Logger.debug(message)
    if Logger.level == Levels.DEBUG then
        Logger.info(message)
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

return Logger
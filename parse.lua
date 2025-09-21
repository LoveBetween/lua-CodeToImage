-- https://github.com/andremm/lua-parser
local parser = require "lua-parser.parser"
local pp = require "lua-parser.pp"

local gpp = require "gpp"

function readAll(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

function writeFile(path, content)
    local f = assert(io.open(path, "w"))
    f:write(content)
    f:close()
end

nClock = os.clock()

local input = readAll(arg[1])

local ast, error_msg = parser.parse(input, arg[1])
local output = gpp.tostring(ast)
writeFile(arg[2], output)
local inputAST = pp.tostring(ast)

local ast2, error_msg2 = parser.parse(output, arg[1]) -- verifying

if (error_msg2) then
    print(error_msg2)
    os.exit(1)
end



local outputAST = pp.tostring(ast2)
if outputAST == pp.tostring(ast) then
    print("CORRECT CODE GENERATED!")
else 
    print("DIFFERENT CODE!")
end
print(("Elapsed time: " .. os.clock()-nClock))

os.exit(0)
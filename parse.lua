-- https://github.com/andremm/lua-parser
local parser = require "lua-parser.parser"
local pp = require "lua-parser.pp"

local translate = require "generate"

function readAll(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

nClock = os.clock()

local p1 = readAll(arg[1])

local ast, error_msg = parser.parse(p1, arg[1])

local output = translate(ast)
print(output)

local ast2, error_msg2 = parser.parse(output, "generatedcode.lua")

if (error_msg2) then
    print(error_msg2)
    os.exit(1)
end

local inputAST = pp.tostring(ast)
local outputAST = pp.tostring(ast2)

print(inputAST)
print(outputAST)

if outputAST == pp.tostring(ast) then
    print("SAME CODE!")
else 
    print("DIFFERENT CODE!")
end




print(("Elapsed time: " .. os.clock()-nClock))

os.exit(0)
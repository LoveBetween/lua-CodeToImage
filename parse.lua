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
--local p2 = readAll(arg[2])

--p1 = p1:gsub(" ", "  ")
--print(p1)

local ast, error_msg = parser.parse(p1, "example.lua")
pp.print(ast)
--local ast2, error_msg2 = parser.parse(p2, "example.lua")

local output = translate(ast)
print(output)
local ast3, error_msg3 = parser.parse(output, "example.lua")
local output3 = pp.tostring(ast3)

if output3 == pp.tostring(ast) then
    print("SAME CODE!")
else 
    print("DIFFERENT CODE!")
end

print(pp.tostring(ast))
print(output3)

print(("Elapsed time: " .. os.clock()-nClock))

print("--------------------")
print(output)


os.exit(0)
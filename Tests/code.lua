--[[
This module impements a pretty printer to the AST
]] op = {
    ["add"] = '+',
    ["sub"] = '-',
    ["mul"] = '*',
    ["div"] = '/',
    ["idiv"] = '//',
    ["mod"] = '%',
    ["pow"] = '^',
    ["concat"] = '..',
    ["band"] = '&',
    ["bor"] = '|',
    ["bxor"] = '~',
    ["shl"] = '<<',
    ["shr"] = '>>',
    ["eq"] = '==',
    ["ne"] = '~=',
    ["lt"] = '<',
    ["gt"] = '>',
    ["le"] = '<=',
    ["ge"] = '>=',
    ["and"] = 'and',
    ["or"] = 'or',
    ["unm"] = '-',
    ["len"] = '#',
    ["bnot"] = '~',
    ["not"] = 'not'
}

local pp = {}

local function pretty(t)
    if type(t) ~= "table" then
        return tostring(t)
    end
    local parts = {}
    for i = 1, #t do
        parts[#parts + 1] = pretty(t[i])
    end
    return table.concat(parts, " ")
end 

local block2str, stm2str, exp2tab, var2tab
local explist2str, varlist2tab, parlist2tab, fieldlist2tab

function flat(...)
    local t = {}
    for _, arg in pairs({...}) do
        if type(arg) == "table" then
            for _, e in pairs(arg) do t[#t + 1] = e end
        else
            t[#t + 1] = arg
        end
    end
    return t
end

local function iscntrl(x)
    if (x >= 0 and x <= 31) or (x == 127) then return true end
    return false
end
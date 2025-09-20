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
    return table.concat(parts, "")
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

local function isprint(x) return not iscntrl(x) end

local function fixed_string(str)
    local new_str = ""
    for i = 1, string.len(str) do
        char = string.byte(str, i)
        if char == 34 then
            new_str = new_str .. string.format("\\\"")
        elseif char == 92 then
            new_str = new_str .. string.format("\\\\")
        elseif char == 7 then
            new_str = new_str .. string.format("\\a")
        elseif char == 8 then
            new_str = new_str .. string.format("\\b")
        elseif char == 12 then
            new_str = new_str .. string.format("\\f")
        elseif char == 10 then
            new_str = new_str .. string.format("\\n")
        elseif char == 13 then
            new_str = new_str .. string.format("\\r")
        elseif char == 9 then
            new_str = new_str .. string.format("\\t")
        elseif char == 11 then
            new_str = new_str .. string.format("\\v")
        else
            if isprint(char) then
                new_str = new_str .. string.format("%c", char)
            else
                new_str = new_str .. string.format("\\%03d", char)
            end
        end
    end
    return new_str
end

local function name2tab(name) return string.format('%s', name) end

-- local function boolean2tab (b)
--   return string.format('"%s"', tostring(b))
-- end

-- local function number2str (n)
--   return string.format('"%s"', tostring(n))
-- end

local function string2str(s) return string.format('"%s"', fixed_string(s)) end

function var2tab(var)
    local tag = var.tag
    local t = {}
    if tag == "Id" then -- `Id{ <string> }
        t = name2tab(var[1])
    elseif tag == "Index" then -- `Index{ expr expr }
        t = {exp2tab(var[1]), "[", exp2tab(var[2]), "]"}
    else
        error("expecting a variable, but got a " .. tag)
    end
    return t
end

function varlist2tab(varlist)
    local l = {}
    for k, v in ipairs(varlist) do
        l[#l + 1] = var2tab(v)
        l[#l + 1] = ","
    end
    l[#l] = nil
    return l
end

function parlist2tab(parlist)
    local l = {}
    local len = #parlist
    local is_vararg = false
    if len > 0 and parlist[len].tag == "Dots" then
        is_vararg = true
        len = len - 1
    end
    local i = 1
    while i <= len do
        l[#l + 1] = var2tab(parlist[i])
        l[#l + 1] = ","
        i = i + 1
    end
    if is_vararg then
        l[#l + 1] = "..."
    else
        table.remove(l, #l) -- remove the ","
    end
    return l
end

function fieldlist2tab(fieldlist)
    local l = {}
    for k, v in ipairs(fieldlist) do
        local tag = v.tag
        if tag == "Pair" then -- `Pair{ expr expr }
            if v[1].tag == "String" then
                l[#l+1] = flat("[",exp2tab(v[1]),"]","=",exp2tab(v[2]))
            else
                l[#l+1] = flat(exp2tab(v[1]),"=",exp2tab(v[2]))
            end
        else -- expr
            l[#l+1] = flat(exp2tab(v))
        end
        l[#l+1] = ","
    end
    if #l > 0 then
        l[#l] = nil
        return l
    else
        return ""
    end
end

function exp2tab(exp)
    local tag = exp.tag
    local t = {}
    if tag == "Nil" then
        t = {"nil"}
    elseif tag == "Dots" then
        t = {"..."}
    elseif tag == "Boolean" then -- `Boolean{ <boolean> }
        t = {tostring(exp[1])}
    elseif tag == "Number" then -- `Number{ <number> }
        t = {tostring(exp[1])}
    elseif tag == "String" then -- `String{ <string> }
        t = {string2str(exp[1])}
    elseif tag == "Function" then -- `Function{ { `Id{ <string> }* `Dots? } block }
        t = {"function (", parlist2tab(exp[1]), ") ", block2str(exp[2]), " end "}
    elseif tag == "Table" then -- `Table{ ( `Pair{ expr expr } | expr )* }
        t = {"{",fieldlist2tab(exp),"} "}
    elseif tag == "Op" then -- `Op{ opid expr expr? }
        t = {op[exp[1]]," ", exp2tab(exp[2])}
        if exp[3] then t = {exp2tab(exp[2]), " ",op[exp[1]]," ", exp2tab(exp[3])} end
    elseif tag == "Paren" then -- `Paren{ expr }
        t = {"(",exp2tab(exp[1]),") "}
    elseif tag == "Call" then -- `Call{ expr expr* }
        t = {exp2tab(exp[1]), "("}
        if exp[2] then
            for i = 2, #exp do t = flat(t, exp2tab(exp[i]), ",") end
            t[#t] = nil
        end
        t = flat(t, ") ")
    elseif tag == "Invoke" then -- `Invoke{ expr `String{ <string> } expr* }
        t = { exp2tab(exp[1]), ":", name2tab(exp[2][1]), "("}
        if exp[3] then
            for i = 3, #exp do t = flat(t, exp2tab(exp[i]), ",") end
            t[#t] = nil
        end
        t = flat(t, ") ")
    elseif tag == "Id" or -- `Id{ <string> }
    tag == "Index" then -- `Index{ expr expr }
        t = {var2tab(exp)}
    else
        error("expecting an expression, but got a " .. tag)
    end
    return t
end

function explist2str(explist)
    local l = {}
    for k, v in ipairs(explist) do l[k] = exp2tab(v) end
    if #l > 0 then
        return l
    else
        return ""
    end
end

function stm2str(stm)
    local tag = stm.tag
    print(tag)
    local t = {}
    if tag == "Do" then -- `Do{ stat* }
        for k, v in ipairs(stm) do t[k] = stm2str(v) end
        return t
    elseif tag == "Set" then -- `Set{ {lhs+} {expr+} }
        t = {varlist2tab(stm[1]), "=", explist2str(stm[2]), " "}
    elseif tag == "While" then -- `While{ expr block }
        t = {" while ", exp2tab(stm[1]), " do ", block2str(stm[2]), " end "}
    elseif tag == "Repeat" then -- `Repeat{ block expr }
        t = {" repeat ", block2str(stm[1]), " until ", exp2tab(stm[2])}
    elseif tag == "If" then -- `If{ (expr block)+ block? }
        for i = 1, #stm - 1, 2 do
            if i == 1 then
                t = {t, " if ", exp2tab(stm[i]), " then ", block2str(stm[i+1])}
            else
                t = {
                    t, " elseif ", exp2tab(stm[i]), " then ", block2str(stm[i+1])
                }
            end
        end
        if #stm % 2 == 1 then t = {t, " else ", block2str(stm[#stm])} end
        t = flat(t, " end ")
    elseif tag == "Fornum" then -- `Fornum{ ident expr expr expr? block }
        t = {
            " for ", var2tab(stm[1]), "=", exp2tab(stm[2]), ",", exp2tab(stm[3])
        }
        if stm[5] then
            t = {t,  ",", exp2tab(stm[4]), " do ", block2str(stm[5]), " end "}
        else
            t = {t, " do ",block2str(stm[4]), " end "}
        end
    elseif tag == "Forin" then -- `Forin{ {ident+} {expr+} block }
        t = {
            " for ", varlist2tab(stm[1]), " in ", explist2str(stm[2]), " do ",
            block2str(stm[3]), " end "
        }
    elseif tag == "Local" then -- `Local{ {ident+} {expr+}? }
        t = { " local ", varlist2tab(stm[1])}
        if #stm[2] > 0 then
            t = {t, "=", explist2str(stm[2])}
        end
        t = flat(t, " ")
    elseif tag == "Localrec" then -- `Localrec{ ident expr }
        print("tag", stm[2][1].tag)
        t = {"local function ", var2tab(stm[1][1]), "(",parlist2tab(stm[2][1][1]),") ", block2str(stm[2][1][2]), " end "}
    elseif tag == "Goto" or -- `Goto{ <string> }
    tag == "Label" then -- `Label{ <string> }
        t = {"::", name2tab(stm[1]) ,"::"}
    elseif tag == "Return" then -- `Return{ <expr>* }
        t = {"return ", explist2str(stm)}
    elseif tag == "Break" then
    elseif tag == "Call" then -- `Call{ expr expr* }
        -- removing ""
        local fn = pretty(exp2tab(stm[1]))
        if string.sub(fn, 1, 1) == "\"" then
          fn = string.sub(fn, 2, -2)
        end
        t = { fn, "("}
        if stm[2] then
            for i = 2, #stm do 
              if i<#stm then
                t = {t , exp2tab(stm[i]), ", "} 
              else
                t = {t,  exp2tab(stm[i])}
              end
            end
        end
        t = flat(t, ") ")
    elseif tag == "Invoke" then -- `Invoke{ expr `String{ <string> } expr* }
        t = {exp2tab(stm[1]),":",name2tab(stm[2][1]), "("}
        if stm[3] then
            for i = 3, #stm do t = {t,  ", ", exp2tab(stm[i])} end
        end
        t = flat(t, ") ")
    else
        error("expecting a statement, but got a " .. tag)
    end
    return t
end

function block2str(block)
    local l = {}
    for k, v in ipairs(block) do 
      l[k] = stm2str(v) 
    end
    return {"\n",l, "\n"}
end

function pp.tostring(t)
    assert(type(t) == "table")
    return pretty(block2str(t))
end

function pp.print(t)
    assert(type(t) == "table")
    print(pp.tostring(t))
end

return pp

op = {
    ["add"]    = '+',
    ["sub"]    = '-',
    ["mul"]    = '*',
    ["div"]    = '/',
    ["idiv"]   = '//',
    ["mod"]    = '%',
    ["pow"]    = '^',
    ["concat"] = '..',
    ["band"]   = '&',
    ["bor"]    = '|',
    ["bxor"]   = '~',
    ["shl"]    = '<<',
    ["shr"]    = '>>',
    ["eq"]     = '==',
    ["ne"]     = '~=',
    ["lt"]     = '<',
    ["gt"]     = '>',
    ["le"]     = '<=',
    ["ge"]     = '>=',
    ["and"]    = 'and',
    ["or"]     = 'or',
    ["unm"]    = '-',
    ["len"]    = '#',
    ["bnot"]   = '~',
    ["not"]    = 'not'
}

local A
local G = {}

local function A(ats)
    if type(ats) ~= "table" or ats.tag == nil then
        return ats
    end
    print(ats.tag, #ats, ats[1])
    local R = G[ats.tag]
    if R == nil then
        print("missing rule for "..ats.tag)
        return A(ats[1])
    end
    return R(ats)
end

G = {
    Block = function(a)
            local r = {}
            for i=1, #a do
                r = {r,"\n", A(a[i])}
            end
            return r 
        end,
    Number = function(a) return {a[1]} end,
    Op = function(a) 
            if #a < 3 then 
                return {op[a[1]], A(a[2])} 
            else
                return {A(a[2]), op[a[1]], A(a[3])} 
            end
        end,
    --stat
    Do = function(a) return {A(a[1])} end,
    Set = function(a) return {A(a[1]), "=", A(a[2])} end,
    While = function(a) return {"while ", A(a[1]), " do ", A(a[2]), " end"} end,
    Repeat = function(a) return {"repeat ", A(a[1]), " until ", A(a[2])} end,
    If = function(a) 
            local r = {}
            for i = 1, #a - 1, 2 do
                if i == 1 then
                    r = {r ,"if ", A(a[i]), " then ", A(a[i + 1])}
                else
                    r = {r , " elseif ", A(a[i]) , " then " , A(a[i + 1])}
                end
            end
            if #a % 2 == 1 then
                r = {r, " else " ,A(a[#a])}
            end
            return {r, " end"}
        end,
    Fornum = function(a) -- here right now
        local r = {"for ", A(a[1]), "=", A(a[2]), ",", A(a[3])}
        for i=4, #a-1 do
            r = {r, ",", A(a[4])}
        end
        return {r, " do ", A(a[#a]), " end"}
    end,
    -- expr
    Nil = function(a) return {"Nil"} end,
    Dots = function(a) return {"..."} end,
    Boolean = function(a) return {a[1]} end,
    Number = function(a) return {a[1]} end,
    String = function(a) return {'"'..a[1]..'"'} end,
    Function = function(a)
            local r = {}
            local b = a[i]
            for i=1, #b do
                r = {r, A(b[i])}
            end
            return {"function", {r, A(a[2])}}
        end,
    Table = function(a)
            local r = {"{"}
            for i=1, #a-1 do
                r = {r, A(a[i]), ","}
            end
            return {{r, A(a[#a])}, "}"}
        end,

    -- apply: Call{ expr expr* }
    Call = function(a)
            local r = {A(a[1]), "("}
            if #a == 1 then
                return {r, ")"}
            else
                for i=2, #a-1 do
                    r = {r, A(a[i]), ","}
                end
                return {r, A(a[#a]), ")"}
            end
        end,

    -- Invoke{ expr `String{ <string> } expr* }
    Invoke = function(a)
        local r = {A(a[1]), ":", A(a[2]), "("}
        for i=3, #a-1 do
            r = {r, A(a[i]), ","}
        end
        return {r, A(a[#a]), ")"}
    end,

    -- lhs: `Id{ <string> } | `Index{ expr expr }
    Id = function(a) return {a[1]} end,
    Index = function(a) return {A(a[1]),".", a[2]} end,
    Pair = function(a) return {a[1][1], " = ", A(a[2])} end
}
    
local ATS = {
    tag = "Op",
    [1] = "add",
    [2] = {
        tag = "Op",
        [1] = "sub",
        [2] = 10,
        [3] = 5
    }
}

local output = A(ATS)

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

return  function(a) return pretty(A(a)) end
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
    if type(ats) ~= "table" then
        return ats
    elseif ats.tag == nil then
        local r = {}
        for i = 1, #ats do
            r[#r+1] = A(ats[i])
        end
        return r
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
    Op = function(a) 
            if #a < 3 then 
                return {op[a[1]], A(a[2])} 
            else
                return {A(a[2]), op[a[1]], A(a[3])} 
            end
        end,
    --stat
    Do = function(a) return {A(a[1])} end,
    Set = function(a) return {A(a[1][1]), "=", A(a[2][1])} end,
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
    Fornum = function(a)
        local r = {"for ", A(a[1]), "=", A(a[2]), ",", A(a[3])}
        for i=4, #a-1 do
            r = {r, ",", A(a[i])}
        end
        return {r, " do ", A(a[#a]), " end"}
    end,
    -- Forin{ {ident+} {expr+} block }          -- for i1, i2... in e1, e2... do b end
    --   | `Local{ {ident+} {expr+}? }               -- local i1, i2... = e1, e2...
    --   | `Localrec{ ident expr }                   -- only used for 'local function'
    --   | `Goto{ <string> }                         -- goto str
    --   | `Label{ <string> }                        -- ::str::
    Forin = function(a)
        local r = {"for ", A(a[1])}
        local i = 2
        while i<=#a and a[i].tag == "Id" do
            r = {r, ",", A(a[i])}
            i = i + 1
        end
        r = {r, " in ", A(a[i])}
        while i<#a and a[i].tag ~= "Block" do
            r = {r, ",", A(a[i])}
            i = i + 1
        end
        return {r, " do ", A(a[#a]), " end"}
    end,
    Local = function(a)
        local r = {"local ", A(a[1])}
        local i = 2
        while i<=#a and a[i].tag == "Id" do
            r = {r, ",", A(a[i])}
            i = i + 1
        end
        r = {r, "=", A(a[i])}
        while i<=#a do
            r = {r, ",", A(a[i])}
            i = i + 1
        end
        return r
    end,

    -- expr
    Nil = function(a) return {"Nil"} end,
    Dots = function(a) return {"..."} end,
    Boolean = function(a) return {a[1]} end,
    Number = function(a) return {a[1]} end,
    String = function(a) return {'"'..a[1]..'"'} end,
        Function = function(a)
        local p = a[1] or {}
        local b = a[2]
        local r = {"function("}
        for i = 1, #p - 1 do
            r = {r, A(p[i]), ","}
        end
        if #p > 0 then
            r = {r, A(p[#p])}
        end
        r = {r, ") ", A(b), " end"}
        return r
    end,
    Return = function(a)
        local r = {"return "}
        for i=1, #a-1 do r = {r, A(a[i]), ","} end
        return {r, A(a[#a])}
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
    Index = function(a)
        local obj = A(a[1])
        local key = a[2]

        if key.tag == "Id" then
            return {obj, ".", key[1]}
        else
            return {obj, "[", A(key), "]"}
        end
    end,
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
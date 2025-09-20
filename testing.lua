local a = {1}
local b = {2,3}
local c = {4,5, "si"}

function flat(...)
    local t = {}
    for _, arg in pairs({...})  do
        if type(arg) == "table" then
            for _, e in pairs(arg) do
                t[#t+1] = e
            end
        else
            t[#t+1] = arg
        end
    end
    return t
end

function append(t, ...)
    for _, arg in pairs({...})  do
        t[#t] = arg
    end
end

print(flat(a, b, c)[6])

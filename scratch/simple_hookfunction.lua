local function x()
    print("x")
end

local old;
old = hookfunction(x, function(func, ...)
    print("hookfunction", ...)
    return old(func, ...)
end)
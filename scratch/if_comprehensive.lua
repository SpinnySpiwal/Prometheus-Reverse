local x = 0

if x == 0 then
    print("x is 0, here, have a 1")
    x = x + 1
end

if x == 0 then
    print("x is 0, here, have a 1? (why are you here? this is broken.)")
else
    print(x)
    if x == 1 then
        print("x is 1, here, have a single 1.")
        for j = 1, 10 do
            print("loop", j)
        end
        local j;
        j = 0
        repeat
            print("on repeat", j)
            j = j + 1
        until j >= 10
        if j == 10 then
            print("repeat test: PASS")
            j = 0
        else
            print("repeat test: FAIL")
        end
        x = x + 1
        if x == 2 then
            print("x is 2, here, have ANOTHER 1.")
            while j < 10 do
                print("while", j)
                j = j + 1
            end
            if j == 10 then
                print("while test: PASS")
            else
                print("while test: FAIL")
            end
        else
            print("decompiler is broken.")
        end
    else
        print("decompiler is broken.")
    end
end

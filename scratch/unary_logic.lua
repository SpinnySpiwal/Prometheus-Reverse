local a = 9
local b = 4
local tbl = { "x", "yz" }

local value = (a % b) + (a / b)
local powv = b ^ 2
local text = tbl[1] .. tbl[2]
local cond = (not false) and (#text == 3) and (powv >= 16) and (value > 0)

if cond then
	print("ok", value, powv, text)
else
	print("bad")
end


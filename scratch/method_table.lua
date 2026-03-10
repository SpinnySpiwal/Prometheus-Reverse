local t = {
	x = 1,
	[2] = 3
}

t[1] = 2

local obj = {
	value = 4,
	bump = function(self, delta)
		self.value = self.value + delta
		return self.value
	end
}

local message = "ab" .. "cd"
local n = -5 + 10
local ok = not false and (n >= 5)

print(obj:bump(t[1] + t[2]), message, ok and "T" or "F")


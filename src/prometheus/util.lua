-- This Script is NOT of the Prometheus-Reverse Project by SpinnySpiwal
-- This script is sourced from the Prometheus Obfuscator by Levno_710.
-- [Heavily Modified & Optimised by SpinnySpiwal]
-- util.lua
-- Overview:
-- This script provides a library of utility functions for the Prometheus Obfuscator.
---@diagnostic disable: deprecated

local string_char, string_sub, string_format, string_gsub, math_random, pairs, newproxy, getmetatable = string.char, string.sub, string.format, string.gsub, math.random, pairs, newproxy, getmetatable

-- Pre-computed escape lookup table for faster character escaping
local ESCAPE_LOOKUP = {}
-- Pre-populate non-printable characters
for i = 0, 31 do
	ESCAPE_LOOKUP[string_char(i)] = string_format("\\%03d", i)
end

for i = 127, 255 do
	ESCAPE_LOOKUP[string_char(i)] = string_format("\\%03d", i)
end

-- Override specific escapes
ESCAPE_LOOKUP["\\"] = "\\\\"
ESCAPE_LOOKUP["\n"] = "\\n"
ESCAPE_LOOKUP["\r"] = "\\r"
ESCAPE_LOOKUP['"'] = '\\"'
ESCAPE_LOOKUP["'"] = "\\'"

local function lookupify(tb)
	local tb2 = {}
	local len = #tb
	for i = 1, len do
		tb2[tb[i]] = true
	end
	return tb2
end

local function unlookupify(tb)
	local tb2 = {}
	local n = 0
	for v in pairs(tb) do
		n = n + 1
		tb2[n] = v
	end
	return tb2
end

-- Convert a fractional part (0 <= frac < 1) to hex fraction string
local function fracToHex(frac)
	if frac == 0 then
		return "0"
	end

	local hexstr = "0123456789ABCDEF"
	local result = ""
	local maxDigits = 13 -- Limit precision to avoid infinite loops

	while frac > 0 and #result < maxDigits do
		frac = frac * 16
		local digit = math.floor(frac)
		result = result .. string.sub(hexstr, digit + 1, digit + 1)
		frac = frac - digit
	end

	return result
end


local function escape(str)
	return string_gsub(str, ".", ESCAPE_LOOKUP)
end

local function chararray(str)
	local len = #str
	local tb = {}
	for i = 1, len do
		tb[i] = string_sub(str, i, i)
	end
	return tb
end

local function keys(tb)
	local keyset = {}
	local n = 0
	for k in pairs(tb) do
		n = n + 1
		keyset[n] = k
	end
	return keyset
end

local function shuffle(tb)
	local len = #tb
	for i = len, 2, -1 do
		local j = math_random(i)
		tb[i], tb[j] = tb[j], tb[i]
	end
	return tb
end

-- Polyfill newproxy for Lua 5.2+
if not newproxy then
	_ENV.ewproxy = function(addmt)
		local proxy = {}
		if addmt then
			setmetatable(proxy, {})
		end
		return proxy
	end
end


local function readonly(obj)
	local r = newproxy(true)
	getmetatable(r).__index = obj
	return r
end

return {
	lookupify = lookupify,
	unlookupify = unlookupify,
	escape = escape,
	chararray = chararray,
	keys = keys,
	shuffle = shuffle,
	readonly = readonly,
	fracToHex = fracToHex,
}

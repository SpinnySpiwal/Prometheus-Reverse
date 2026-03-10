--> For anti-decompiler versions <-- ~ SpinnySpiwal
local function getVersionedStep(stepName)
	local version = _G['jit'] and "luajit" or (_G._VERSION):match("^Lua (%d%.%d)$"):gsub("%.", "")
	return require("prometheus.steps." .. stepName .. ".output-" .. version)
end

return {
	Decompile = require("src.prometheus.steps.Decompile"),
	EncryptStrings = require("src.prometheus.steps.EncryptStrings"),
	DecryptStrings = require("src.prometheus.steps.DecryptStrings"),
	ReverseConstantArray = require("src.prometheus.steps.ReverseConstantArray"),
	ConstantArray = require("src.prometheus.steps.ConstantArray"),
	Vmify = require("src.prometheus.steps.Vmify"),
}
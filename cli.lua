--> SpinnySpiwal <--
--> Better Prometheus CLI <--

arg = arg or {}

local Config = "Reverse"
local inputFile = "input.txt"
local outputFile = "output.txt"
local printOutput = false
local silenceEnabled = false
local disableLogger = false

-- Parse command line arguments
for k, v in pairs(arg) do
	if v == "--input" or v == "--i" then
		inputFile = arg[k + 1]
	elseif v == "--output" or v == "--o" then
		outputFile = arg[k + 1]
	elseif v == "--preset" or v == "--p" then
		Config = arg[k + 1]
	elseif v == "--silent" or v == "--s" then
		silenceEnabled = true
		disableLogger = true
	elseif v == "--print" then
		printOutput = true
		disableLogger = true
	elseif v == "-help" then
		print("Usage: luajit cli.lua [options]")
		print("  --input, --i <file>    Input file (default: input.txt)")
		print("  --output, --o <file>   Output file (default: output.txt)")
		print("  --preset, --p <name>   Preset name (default: Reverse)")
		print("  --prettyprint, --pp    Beautify output")
		print("  --version, --v <ver>   Lua version (Lua51, Luau)")
		print("  --silent, --s          Disable prompts and logging")
		print("  --print                Print output to console")
		return
	end
end

-- Handle input file
local src = io.open(inputFile, "r")
if not src then
	if not silenceEnabled then
		print("Input file does not exist. Create it? [y/n]")
	end
	local ans = silenceEnabled and "y" or io.read():lower()
	if ans == "y" then
		io.open(inputFile, "w"):write('print("Hello, World!")')
		src = io.open(inputFile, "r")
	else
		error("Input file does not exist.")
	end
end

local file = io.open(outputFile, "w")
assert(file, "Could not open output file.")

local customName = "prometheus"
local Obfuscator = require("src/" .. customName)

-- Apply additional options
for k, v in pairs(arg) do
	if v == "--beautified" or v == "--pp" or v == "--prettyprint" then
		Obfuscator.Presets[Config].PrettyPrint = true
	elseif v == "--version" or v == "--v" then
		Obfuscator.Presets[Config].LuaVersion = arg[k + 1]
	end
end

if disableLogger then
	Obfuscator.Logger.logLevel = Obfuscator.Logger.LogLevel.Error
end

local pipeline = Obfuscator.Pipeline:fromConfig(Obfuscator.Presets[Config])

local start = os.clock()

---@diagnostic disable-next-line: need-check-nil
local output = pipeline:apply(src:read("*a"))

if not printOutput and not silenceEnabled then
	print("--> Obfuscated in " .. (os.clock() - start) .. "s")
end

file:write(output)

if printOutput then
	print(output)
end

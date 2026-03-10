--> This script was created, developed & polished by SpinnySpiwal!
--> tests_reverse.lua
--> Description: This script is used to test the reverse engineering capabilities of the Prometheus-Reverse project.

local Prometheus = require("src.prometheus")

local ciMode = false
local iterationCount = 5
local writeArtifacts = true

for _, currArg in ipairs(arg) do
	if currArg == "--CI" then
		ciMode = true
	elseif currArg == "--no-artifacts" then
		writeArtifacts = false
	else
		local iterationValue = currArg:match("^%-%-iterations=(%d+)$")
		if iterationValue then
			iterationCount = math.max(tonumber(iterationValue) or 1, 1)
		end
	end
end

Prometheus.colors.enabled = true
Prometheus.Logger.logLevel = Prometheus.Logger.LogLevel.Error

local vmifyPipeline = Prometheus.Pipeline:fromConfig(Prometheus.Presets.Vmify)
local reversePipeline = Prometheus.Pipeline:fromConfig(Prometheus.Presets.Reverse)
local encryptStringsPipeline = Prometheus.Pipeline:fromConfig(Prometheus.Presets.EncryptStrings)
local decryptStringsPipeline = Prometheus.Pipeline:fromConfig(Prometheus.Presets.DecryptStrings)
local constantArrayPipeline = Prometheus.Pipeline:fromConfig(Prometheus.Presets.ConstantArray)
local reverseConstantArrayPipeline = Prometheus.Pipeline:fromConfig(Prometheus.Presets.ReverseConstantArray)

local function fixture(name, source)
	return {
		name = name,
		source = source or ("scratch/" .. name .. ".lua"),
		vmOut = "scratch/" .. name .. ".vm.lua",
		revOut = "scratch/" .. name .. ".rev.lua",
		encOut = "scratch/" .. name .. ".enc.lua",
		decOut = "scratch/" .. name .. ".dec.lua",
		constOut = "scratch/" .. name .. ".const.lua",
		revConstOut = "scratch/" .. name .. ".revconst.lua",
	}
end

local fixtures = {
	fixture("simple_print"),
	fixture("for_print"),
	fixture("while_print"),
	fixture("while_if"),
	fixture("repeat_print"),
	fixture("if"),
	fixture("if_comprehensive"),
	fixture("simple_roblox"),
	fixture("simple_hookfunction"),
	fixture("method_table"),
	fixture("unary_logic"),
}

local fixtureRequires = {
	simple_roblox = { "Instance", "game", "Vector3", "Color3" },
	simple_hookfunction = { "hookfunction" },
}

local function shallowcopy(orig)
	if type(orig) ~= "table" then
		return orig
	end
	local copy = {}
	for k, v in pairs(orig) do
		copy[k] = v
	end
	return copy
end

local function readAll(path)
	local file = io.open(path, "r")
	if not file then
		return nil, "unable to open file: " .. path
	end
	local content = file:read("*a")
	file:close()
	return content
end

local function writeAll(path, content)
	local file = io.open(path, "w")
	if not file then
		return false, "unable to open output file: " .. path
	end
	file:write(content)
	file:close()
	return true
end

local function runAndCapture(func)
	local output = {}
	local env = shallowcopy(getfenv(func))
	env.print = function(...)
		local args = { ... }
		local line = {}
		for i = 1, #args do
			line[i] = tostring(args[i])
		end
		output[#output + 1] = table.concat(line, "\t")
	end
	setfenv(func, env)
	local ok = pcall(func)
	return ok, table.concat(output, "\n") .. (#output > 0 and "\n" or "")
end

local function validate(referenceFunc, candidateFunc)
	local okRef, outRef = runAndCapture(referenceFunc)
	if not okRef then
		return false, outRef, "", "reference runtime failure"
	end

	local okCandidate, outCandidate = runAndCapture(candidateFunc)
	if not okCandidate then
		return false, outRef, outCandidate, "candidate runtime failure"
	end

	if outRef ~= outCandidate then
		return false, outRef, outCandidate, "output mismatch"
	end

	return true, outRef, outCandidate
end

local function hasRequiredGlobals(requiredGlobals)
	if not requiredGlobals then
		return true
	end
	for i = 1, #requiredGlobals do
		local name = requiredGlobals[i]
		if _G[name] == nil then
			return false, name
		end
	end
	return true
end

local colors = Prometheus.colors

-- =====================
-- Reverse Roundtrip Tests
-- =====================

print(string.format(
	"Running reverse roundtrip tests (iterations=%d, fixtures=%d)...",
	iterationCount, #fixtures
))

local failures = 0

for i = 1, #fixtures do
	local fx = fixtures[i]
	local name = fx.name
	local requires = fixtureRequires[name]
	local fixtureFailed = false
	local fixtureCompileOnly = false

	local canRun, missingGlobal = hasRequiredGlobals(requires)
	if not canRun then
		print(colors("[INFO]    ", "yellow") .. name ..
			" (running compile-only; missing runtime global: " .. missingGlobal .. ")")
		fixtureCompileOnly = true
	end

	local code, readErr = readAll(fx.source)
	if not code then
		print(colors("[FAILED]  ", "red") .. name .. " (" .. readErr .. ")")
		failures = failures + 1
	else
		print(colors("[RUNNING] ", "magenta") .. name)
		for iteration = 1, iterationCount do
			vmifyPipeline.Seed = math.random(-2^22, 2^22 - 1)
			local vmified = vmifyPipeline:apply(code)
			local reversed = reversePipeline:apply(vmified)

			if writeArtifacts then
				local okVm, vmErr = writeAll(fx.vmOut, vmified)
				local okRev, revErr = writeAll(fx.revOut, reversed)
				if not okVm or not okRev then
					print(colors("[FAILED]  ", "red") .. name ..
						" (artifact write error: " .. tostring(vmErr or revErr) .. ")")
					failures = failures + 1
					fixtureFailed = true
					break
				end
			end

			local referenceFunc = loadstring(code)
			if not referenceFunc then
				print(colors("[FAILED]  ", "red") .. name .. " (reference compile error)")
				failures = failures + 1
				fixtureFailed = true
				break
			end

			local reversedFunc, compileErr = loadstring(reversed)
			if not reversedFunc then
				print(colors("[FAILED]  ", "red") .. name ..
					" (reverse compile error @ iteration " .. iteration .. ")")
				print("[ERROR] ", compileErr)
				print("[SOURCE]", reversed)
				failures = failures + 1
				fixtureFailed = true
				break
			end

			if not fixtureCompileOnly then
				local ok, outRef, outCandidate, reason = validate(referenceFunc, reversedFunc)
				if not ok then
					print(colors("[FAILED]  ", "red") .. name ..
						" (" .. reason .. ", iteration " .. iteration .. ")")
					print("[OUTA]    ", outRef)
					print("[OUTB]    ", outCandidate)
					print("[SOURCE]", reversed)
					failures = failures + 1
					fixtureFailed = true
					break
				end
			end
		end

		if not fixtureFailed then
			if fixtureCompileOnly then
				print(colors("[SKIPPED] ", "yellow") .. name .. " (runtime validation skipped)")
			else
				print(colors("[PASSED]  ", "green") .. name)
			end
		end
	end
end

if failures < 1 then
	print(colors("[PASSED]  ", "green") .. "All reverse tests passed!")
else
	print(colors("[FAILED]  ", "red") .. "Some reverse tests failed!")
end

-- =====================
-- String Encryption/Decryption Tests
-- =====================

print("")
print(string.format(
	"Running string encryption/decryption roundtrip tests (iterations=%d, fixtures=%d)...",
	iterationCount, #fixtures
))

local stringFailures = 0

for i = 1, #fixtures do
	local fx = fixtures[i]
	local name = fx.name
	local requires = fixtureRequires[name]
	local fixtureFailed = false
	local fixtureCompileOnly = false

	local canRun, missingGlobal = hasRequiredGlobals(requires)
	if not canRun then
		print(colors("[INFO]    ", "yellow") .. name ..
			" (running compile-only; missing runtime global: " .. missingGlobal .. ")")
		fixtureCompileOnly = true
	end

	local code, readErr = readAll(fx.source)
	if not code then
		print(colors("[FAILED]  ", "red") .. name .. " (" .. readErr .. ")")
		stringFailures = stringFailures + 1
	else
		print(colors("[RUNNING] ", "magenta") .. name .. " (string encrypt/decrypt)")
		for iteration = 1, iterationCount do
			encryptStringsPipeline.Seed = math.random(-2^22, 2^22 - 1)
			local encrypted = encryptStringsPipeline:apply(code)
			local decrypted = decryptStringsPipeline:apply(encrypted)

			if writeArtifacts then
				local okEnc, encErr = writeAll(fx.encOut, encrypted)
				local okDec, decErr = writeAll(fx.decOut, decrypted)
				if not okEnc or not okDec then
					print(colors("[FAILED]  ", "red") .. name ..
						" (artifact write error: " .. tostring(encErr or decErr) .. ")")
					stringFailures = stringFailures + 1
					fixtureFailed = true
					break
				end
			end

			local referenceFunc = loadstring(code)
			if not referenceFunc then
				print(colors("[FAILED]  ", "red") .. name .. " (reference compile error)")
				stringFailures = stringFailures + 1
				fixtureFailed = true
				break
			end

			local decryptedFunc, compileErr = loadstring(decrypted)
			if not decryptedFunc then
				print(colors("[FAILED]  ", "red") .. name ..
					" (decrypt compile error @ iteration " .. iteration .. ")")
				print("[ERROR] ", compileErr)
				print("[SOURCE]", decrypted)
				stringFailures = stringFailures + 1
				fixtureFailed = true
				break
			end

			if not fixtureCompileOnly then
				local ok, outRef, outCandidate, reason = validate(referenceFunc, decryptedFunc)
				if not ok then
					print(colors("[FAILED]  ", "red") .. name ..
						" (" .. reason .. ", iteration " .. iteration .. ")")
					print("[OUTA]    ", outRef)
					print("[OUTB]    ", outCandidate)
					print("[SOURCE]", decrypted)
					stringFailures = stringFailures + 1
					fixtureFailed = true
					break
				end
			end
		end

		if not fixtureFailed then
			if fixtureCompileOnly then
				print(colors("[SKIPPED] ", "yellow") .. name .. " (runtime validation skipped)")
			else
				print(colors("[PASSED]  ", "green") .. name)
			end
		end
	end
end

if stringFailures < 1 then
	print(colors("[PASSED]  ", "green") .. "All string encryption/decryption tests passed!")
else
	print(colors("[FAILED]  ", "red") .. "Some string encryption/decryption tests failed!")
end

-- =====================
-- Constant Array Tests
-- =====================

print("")
print(string.format(
	"Running constant array roundtrip tests (iterations=%d, fixtures=%d)...",
	iterationCount, #fixtures
))

local constantArrayFailures = 0

for i = 1, #fixtures do
	local fx = fixtures[i]
	local name = fx.name
	local requires = fixtureRequires[name]
	local fixtureFailed = false
	local fixtureCompileOnly = false

	local canRun, missingGlobal = hasRequiredGlobals(requires)
	if not canRun then
		print(colors("[INFO]    ", "yellow") .. name ..
			" (running compile-only; missing runtime global: " .. missingGlobal .. ")")
		fixtureCompileOnly = true
	end

	local code, readErr = readAll(fx.source)
	if not code then
		print(colors("[FAILED]  ", "red") .. name .. " (" .. readErr .. ")")
		constantArrayFailures = constantArrayFailures + 1
	else
		print(colors("[RUNNING] ", "magenta") .. name .. " (constant array)")
		for iteration = 1, iterationCount do
			constantArrayPipeline.Seed = math.random(-2^22, 2^22 - 1)
			local constArrayed = constantArrayPipeline:apply(code)
			local reversed = reverseConstantArrayPipeline:apply(constArrayed)

			if writeArtifacts then
				local okConst, constErr = writeAll(fx.constOut, constArrayed)
				local okRevConst, revConstErr = writeAll(fx.revConstOut, reversed)
				if not okConst or not okRevConst then
					print(colors("[FAILED]  ", "red") .. name ..
						" (artifact write error: " .. tostring(constErr or revConstErr) .. ")")
					constantArrayFailures = constantArrayFailures + 1
					fixtureFailed = true
					break
				end
			end

			local referenceFunc = loadstring(code)
			if not referenceFunc then
				print(colors("[FAILED]  ", "red") .. name .. " (reference compile error)")
				constantArrayFailures = constantArrayFailures + 1
				fixtureFailed = true
				break
			end

			local reversedFunc, compileErr = loadstring(reversed)
			if not reversedFunc then
				print(colors("[FAILED]  ", "red") .. name ..
					" (reverse constant array compile error @ iteration " .. iteration .. ")")
				print("[ERROR] ", compileErr)
				print("[SOURCE]", reversed)
				constantArrayFailures = constantArrayFailures + 1
				fixtureFailed = true
				break
			end

			if not fixtureCompileOnly then
				local ok, outRef, outCandidate, reason = validate(referenceFunc, reversedFunc)
				if not ok then
					print(colors("[FAILED]  ", "red") .. name ..
						" (" .. reason .. ", iteration " .. iteration .. ")")
					print("[OUTA]    ", outRef)
					print("[OUTB]    ", outCandidate)
					print("[SOURCE]", reversed)
					constantArrayFailures = constantArrayFailures + 1
					fixtureFailed = true
					break
				end
			end
		end

		if not fixtureFailed then
			if fixtureCompileOnly then
				print(colors("[SKIPPED] ", "yellow") .. name .. " (runtime validation skipped)")
			else
				print(colors("[PASSED]  ", "green") .. name)
			end
		end
	end
end

if constantArrayFailures < 1 then
	print(colors("[PASSED]  ", "green") .. "All constant array tests passed!")
else
	print(colors("[FAILED]  ", "red") .. "Some constant array tests failed!")
end

-- =====================
-- Final Summary
-- =====================

print("")
local totalFailures = failures + stringFailures + constantArrayFailures
if totalFailures < 1 then
	print(colors("[PASSED]  ", "green") .. "All tests passed!")
	return 0
end

print(colors("[FAILED]  ", "red") .. "Some tests failed! (reverse: " .. failures .. ", strings: " .. stringFailures .. ", constantArray: " .. constantArrayFailures .. ")")
if ciMode then
	error("Tests failed!")
end

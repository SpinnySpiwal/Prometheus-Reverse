--> This Script is Part of the Prometheus-Reverse Project by SpinnySpiwal

return {


	["Minify"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "Mangled",
		PrettyPrint = true,
		Seed = 0,
		Steps = {},
	},

	--> Compilation & Decompilation <--
	--> NOTE: Decompilation is not guaranteed to be 100% accurate or successful. You
	--> NOTE: You WILL lose variable names. And probably if structure sometimes.
	--> NOTE: The code should STILL run the same. <--
	--> ~ SpinnySpiwal

	["Vmify"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "Mangled",
		PrettyPrint = true,
		Seed = 0,
		Steps = {
			{ Name = "Vmify", Settings = {} },
		},
	},

	["Reverse"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "Mangled",
		PrettyPrint = true,
		Seed = 0,
		Steps = {
			{ Name = "Decompile", Settings = {} },
		},
	},



	--> Encryption & Decryption <--
	--> NOTE: Decryption should be 100% Accurate. If it isn't report it to me and I'll fix it ASAP. <--
	--> NOTE: VANILLA PROMETHEUS ONLY. I AM NOT DEALING WITH FORKS. <--
	--> ~ SpinnySpiwal

	["EncryptStrings"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "Mangled",
		PrettyPrint = true,
		Seed = 0,
		Steps = {
			{ Name = "EncryptStrings", Settings = {} },
		},
	},

	["DecryptStrings"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "Mangled",
		PrettyPrint = true,
		Seed = 0,
		Steps = {
			{ Name = "DecryptStrings", Settings = {} },
		},
	},

	--> Constant Array <--
	--> This step was extremely easy to create a reverse step for. <--
	--> Again, bugs likely included, no guarantees of 100% accuracy. <--
	--> If there is a bug, report it to me and I'll fix it ASAP. <--
	--> ~ SpinnySpiwal

	["ConstantArray"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "Mangled",
		PrettyPrint = true,
		Seed = 0,
		Steps = {
			{ Name = "ConstantArray", Settings = {} },
		},
	},

	["ReverseConstantArray"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "Mangled",
		PrettyPrint = true,
		Seed = 0,
		Steps = {
			{ Name = "ReverseConstantArray", Settings = {} },
		},
	},
}

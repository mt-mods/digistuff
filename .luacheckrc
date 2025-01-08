unused_args = false
max_line_length = 300  -- TODO: fix line lengths
--std = "luanti+max"

globals = {
	"digistuff",
	"digilines",
}

read_globals = {
	-- Builtin
	"core",
	"minetest",
	table = {fields = {"copy"}},
	"vector",
	"ItemStack",
	"DIR_DELIM",

	-- Mod Deps
	"default",
	"mesecon",
	"screwdriver",
	"QoS",
	"vizlib",
}

exclude_files = {
	"**/spec/**",
}


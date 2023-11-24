unused_args = false
max_line_length = 300  -- TODO: fix line lengths

globals = {
    "minetest",
	"digistuff",
	"digilines",
}

read_globals = {
	-- Builtin
	table = {fields = {"copy"}},

	"vector",
	"ItemStack",
	"DIR_DELIM",

	-- Mod Deps
	"default",
	"mesecon",
	"screwdriver",
	"QoS"
}

exclude_files = {
	"**/spec/**",
}

digistuff = {}

local components = {
	"touchscreen",
	"light",
	"noteblock",
	"nic",
	"camera",
	"button",
	"panel",
	"piezo",
	"detector",
	"conductors",
}
for _,name in ipairs(components) do
	dofile(string.format("%s%s%s.lua",minetest.get_modpath(minetest.get_current_modname()),DIR_DELIM,name))
end

if (not minetest.global_exists("mesecon")) or type(mesecon.lc_docs) ~= "table" then return end

local examples = {
	["Digilines Piston"] = "piston.lua",
	["Digilines Button"] = "button.lua",
	["Digilines I/O Expander"] = "ioexpander.lua",
	["Digilines EEPROM/SRAM"] = "memory.lua",
	["Digilines Dimmable Light"] = "light.lua",
}

for k,v in pairs(examples) do
	local f = io.open(minetest.get_modpath("digistuff")..DIR_DELIM.."lc_examples"..DIR_DELIM..v,"r")
	mesecon.lc_docs.examples[k] = f:read("*all")
	f:close()
end

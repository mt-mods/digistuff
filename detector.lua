
local formspec = "size[8,4]"..
	"field[1.3,1;6,1;channel;Channel;${channel}]"..
	"field[1.3,2;6,1.3;radius;Radius;${radius}]"..
	"button_exit[2.5,3;3,1;submit;Save]"

minetest.register_node("digistuff:detector", {
	description = "Digilines Player Detector",
	tiles = {
		"digistuff_digidetector.png"
	},
	sounds = default and default.node_sound_stone_defaults(),
	groups = {cracky = 2},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", formspec)
		meta:set_int("radius", 6)
		minetest.get_node_timer(pos):start(1)
	end,
	on_receive_fields = function(pos, _, fields, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return
		end
		local meta = minetest.get_meta(pos)
		if fields.channel then
			meta:set_string("channel", fields.channel)
		end
		if fields.radius then
			local value = math.max(1, math.min(10, tonumber(fields.radius) or 6))
			meta:set_int("radius", value)
		end
	end,
	on_timer = function(pos)
		local meta = minetest.get_meta(pos)
		local radius = meta:get_int("radius")
		local found = {}
		for _,player in pairs(minetest.get_connected_players()) do
			if vector.distance(pos, player:get_pos()) <= radius then
				table.insert(found, player:get_player_name())
			end
		end
		if #found > 0 then
			local channel = meta:get_string("channel")
			digilines.receptor_send(pos, digilines.rules.default, channel, found)
		end
		return true
	end,
	digiline = {
		receptor = {}
	},
	_digistuff_channelcopier_fieldname = "channel",
})

minetest.register_lbm({
	label = "Digistuff detector update",
	name = "digistuff:detector_update",
	nodenames = {"digistuff:detector"},
	run_at_every_load = false,
	action = function(pos)
		local meta = minetest.get_meta(pos)
		if not meta:get("radius") then
			meta:set_int("radius", 6)
		end
		minetest.get_node_timer(pos):start(1)
	end,
})

minetest.register_craft({
	output = "digistuff:detector",
	recipe = {
		{"mesecons_detector:object_detector_off"},
		{"mesecons_luacontroller:luacontroller0000"},
		{"digilines:wire_std_00000000"}
	}
})

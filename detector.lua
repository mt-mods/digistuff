
local formspec = "size[8,4]"..
	"field[1.3,1;6,1;channel;Channel;${channel}]"..
	"field[1.3,2;6,1.3;radius;Radius;${radius}]"..
	"button_exit[4,3;3,1;submit;Save]"

local function get_formspec(enabled)
	if enabled then
		return formspec.."button[1,3;3,1;disable;Disable]"
	else
		return formspec.."button[1,3;3,1;enable;Enable]"
	end
end

local function search_for_players(pos, send_empty)
	local meta = minetest.get_meta(pos)
	local radius = meta:get_int("radius")
	local found = {}
	for _,player in pairs(minetest.get_connected_players()) do
		if vector.distance(pos, player:get_pos()) <= radius then
			table.insert(found, player:get_player_name())
		end
	end
	if #found > 0 or send_empty == true then
		local channel = meta:get_string("channel")
		digilines.receptor_send(pos, digilines.rules.default, channel, found)
	end
	return true
end

local function show_area(pos, node, player)
	if not player or player:get_wielded_item():get_name() ~= "" then
		-- Only show area when using an empty hand
		return
	end
	local radius = minetest.get_meta(pos):get_int("radius")
	vizlib.draw_sphere(pos, radius, {player = player})
end

minetest.register_node("digistuff:detector", {
	description = "Digilines Player Detector",
	tiles = {
		"digistuff_digidetector.png"
	},
	sounds = default and default.node_sound_stone_defaults(),
	groups = {cracky = 2},
	is_ground_content = false,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", get_formspec(true))
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
		if fields.enable then
			meta:set_string("formspec", get_formspec(true))
			minetest.get_node_timer(pos):start(1)
		elseif fields.disable then
			meta:set_string("formspec", get_formspec(false))
			minetest.get_node_timer(pos):stop()
		end
	end,
	on_timer = search_for_players,
	on_punch = minetest.get_modpath("vizlib") and show_area or nil,
	digiline = {
		receptor = {},
		effector = {
			action = function(pos, node, channel, msg)
				local meta = minetest.get_meta(pos)
				if channel ~= meta:get_string("channel") then return end
				if type(msg) == "table" then
					if msg.radius then
						local value = math.max(1, math.min(10, tonumber(msg.radius) or 1))
						meta:set_int("radius", value)
					end
					if msg.command == "get" then
						search_for_players(pos, true)
					end
				elseif msg == "GET" or msg == "get" then
					search_for_players(pos, true)
				end
			end,
		},
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
		meta:set_string("formspec", get_formspec(true))
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

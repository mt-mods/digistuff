
local formspec = "size[8,4]"..
	"field[1.3,1;6,1;channel;Channel;${channel}]"..
	"field[1.3,2;3,1.3;radius;Radius;${radius}]"..
	"field[4.3,2;3,1.3;distance;Distance;${distance}]"..
	"button_exit[4,3;3,1;submit;Save]"

local function get_formspec(enabled)
	if enabled then
		return formspec.."button[1,3;3,1;disable;Disable]"
	else
		return formspec.."button[1,3;3,1;enable;Enable]"
	end
end

local function get_search_spot(pos, meta)
	local distance = meta:get_int("distance")
	local dir = minetest.facedir_to_dir(minetest.get_node(pos).param2)
	local spot = vector.add(pos, vector.multiply(dir, -distance))
	local node = minetest.get_node(spot)
	while node.name == "air" and pos.y - spot.y < 10 do
		spot.y = spot.y - 1
		node = minetest.get_node(spot)
	end
	if node.name == "air" or node.name == "ignore" then
		-- Default to directly in front of camera if ground is not found.
		spot.y = pos.y
	end
	return spot
end

local function search_for_players(pos, send_empty)
	local meta = minetest.get_meta(pos)
	local spot = get_search_spot(pos, meta)
	local radius = meta:get_int("radius")
	local found = {}
	for _,player in pairs(minetest.get_connected_players()) do
		if vector.distance(spot, player:get_pos()) <= radius then
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
	local meta = minetest.get_meta(pos)
	local spot = get_search_spot(pos, meta)
	local radius = meta:get_int("radius")
	vizlib.draw_sphere(spot, radius, {player = player})
end

minetest.register_node("digistuff:camera", {
	description = "Digilines Camera",
	tiles = {
		"digistuff_camera_top.png",
		"digistuff_camera_bottom.png",
		"digistuff_camera_right.png",
		"digistuff_camera_left.png",
		"digistuff_camera_back.png",
		"digistuff_camera_front.png",
	},
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.1,-0.5,-0.28,0.1,-0.3,0.3}, -- Camera Body
			{-0.045,-0.42,-0.34,0.045,-0.36,-0.28}, -- Lens
			{-0.05,-0.9,-0.05,0.05,-0.5,0.05}, -- Pole
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.1,-0.5,-0.34,0.1,-0.3,0.3},
		}
	},
	sounds = default and default.node_sound_stone_defaults(),
	groups = {cracky = 2},
	is_ground_content = false,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", get_formspec(true))
		meta:set_int("radius", 1)
		meta:set_int("distance", 0)
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
			local value = math.max(1, math.min(10, tonumber(fields.radius) or 1))
			meta:set_int("radius", value)
		end
		if fields.distance then
			local value = math.max(0, math.min(20, tonumber(fields.distance) or 0))
			meta:set_int("distance", value)
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
					if msg.distance then
						local value = math.max(0, math.min(20, tonumber(msg.distance) or 0))
						meta:set_int("distance", value)
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
	label = "Digistuff camera update",
	name = "digistuff:camera_update",
	nodenames = {"digistuff:camera"},
	run_at_every_load = false,
	action = function(pos)
		local meta = minetest.get_meta(pos)
		if not meta:get("radius") then
			meta:set_int("radius", 1)
		end
		if not meta:get("distance") then
			meta:set_int("distance", 0)
		end
		meta:set_string("formspec", get_formspec(true))
		minetest.get_node_timer(pos):start(1)
	end,
})

minetest.register_craft({
	output = "digistuff:camera",
	recipe = {
		{"homedecor:plastic_sheeting","homedecor:plastic_sheeting","homedecor:plastic_sheeting"},
		{"default:glass","homedecor:ic","mesecons_luacontroller:luacontroller0000"},
		{"homedecor:plastic_sheeting","homedecor:plastic_sheeting","homedecor:plastic_sheeting"},
	}
})

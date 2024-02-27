if not minetest.get_modpath("mesecons_mvps") then
	minetest.log("error","mesecons_mvps is not installed - digilines piston will not be available!")
	return
end

local function extend(pos, node, max_push, sound)
	local dir = vector.multiply(minetest.facedir_to_dir(node.param2), -1)
	local pusher_pos = vector.add(pos, dir)
	local owner = minetest.get_meta(pos):get_string("owner")
	local success, _, oldstack = mesecon.mvps_push(pusher_pos, dir, max_push, owner)
	if not success then return end
	if sound == "digilines" then
		minetest.sound_play("digistuff_piston_extend", {pos = pos, max_hear_distance = 20, gain = 0.6})
	elseif sound == "mesecons" then
		minetest.sound_play("piston_extend", {pos = pos, max_hear_distance = 20, gain = 0.6})
	end
	minetest.swap_node(pos, {name = "digistuff:piston_ext", param2 = node.param2})
	minetest.set_node(pusher_pos, {name = "digistuff:piston_pusher", param2 = node.param2})
	mesecon.mvps_move_objects(pusher_pos, dir, oldstack)
end

local function retract(pos, node, max_pull, allsticky, sound)
	local dir = minetest.facedir_to_dir(node.param2)
	local pusher_pos = vector.add(pos, vector.multiply(dir, -1))
	if minetest.get_node(pusher_pos).name == "digistuff:piston_pusher" then
		minetest.remove_node(pusher_pos)
		minetest.check_for_falling(pusher_pos)
	end
	if sound == "digilines" then
		minetest.sound_play("digistuff_piston_retract", {pos = pos, max_hear_distance = 20, gain = 0.6})
	elseif sound == "mesecons" then
		minetest.sound_play("piston_retract", {pos = pos, max_hear_distance = 20, gain = 0.6})
	end
	minetest.swap_node(pos, {name = "digistuff:piston", param2 = node.param2})
	if type(max_pull) ~= "number" or max_pull <= 0 then return end  -- not sticky
	local pullpos = vector.add(pos, vector.multiply(dir, -2))
	local owner = minetest.get_meta(pos):get_string("owner")
	local pull = allsticky and mesecon.mvps_pull_all or mesecon.mvps_pull_single
	local success, _, oldstack = pull(pullpos, dir, max_pull, owner)
	if success then
		mesecon.mvps_move_objects(pullpos, vector.multiply(dir, -1), oldstack, -1)
	end
end

minetest.register_node("digistuff:piston", {
	description = "Digilines Piston",
	groups = {cracky = 3},
	is_ground_content = false,
	paramtype2 = "facedir",
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec","field[channel;Channel;${channel}")
	end,
	after_place_node = mesecon.mvps_set_owner,
	tiles = {
		"digistuff_piston_sides.png^[transformR180",
		"digistuff_piston_sides.png",
		"digistuff_piston_sides.png^[transformR90",
		"digistuff_piston_sides.png^[transformR270",
		"digistuff_camera_pole.png",
		"digistuff_camera_pole.png",
	},
	on_receive_fields = function(pos, formname, fields, sender)
		if minetest.is_protected(pos, sender:get_player_name()) then return end
		if fields.channel then
			minetest.get_meta(pos):set_string("channel", fields.channel)
		end
	end,
	_digistuff_channelcopier_fieldname = "channel",
	digiline = {
		wire = {
			rules = {
				{x = 1, y = 0, z = 0},
				{x =-1, y = 0, z = 0},
				{x = 0, y = 1, z = 0},
				{x = 0, y =-1, z = 0},
				{x = 0, y = 0, z = 1},
				{x = 0, y = 0, z =-1},
			},
		},
		effector = {
			action = function(pos,node,channel,msg)
				local setchan = minetest.get_meta(pos):get_string("channel")
				if channel ~= setchan then return end
				if msg == "extend" then
					extend(pos, node, 16, "digilines")
				elseif type(msg) == "table" and msg.action == "extend" then
					local max_push = 16
					if type(msg.max) == "number" then
						max_push = math.max(0, math.min(16, math.floor(msg.max)))
					end
					extend(pos, node, max_push, msg.sound or "digilines")
				end
			end
		},
	},
})

minetest.register_node("digistuff:piston_ext", {
	description = "Digilines Piston Extended (you hacker you!)",
	groups = {cracky = 3, not_in_creative_inventory = 1},
	is_ground_content = false,
	paramtype2 = "facedir",
	tiles = {
		"digistuff_piston_sides.png^[transformR180",
		"digistuff_piston_sides.png",
		"digistuff_piston_sides.png^[transformR90",
		"digistuff_piston_sides.png^[transformR270",
		"digistuff_camera_pole.png",
		"digistuff_camera_pole.png",
	},
	drop = "digistuff:piston",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,-0.3,0.5,0.5,0.5},
			{-0.2,-0.2,-0.5,0.2,0.2,-0.3},
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,-1.5,0.5,0.5,0.5},
		}
	},
	_digistuff_channelcopier_fieldname = "channel",
	on_rotate = false,
	on_receive_fields = function(pos, formname, fields, sender)
		if minetest.is_protected(pos, sender:get_player_name()) then return end
		if fields.channel then
			minetest.get_meta(pos):set_string("channel", fields.channel)
		end
	end,
	after_dig_node = function(pos,node)
		local dir = vector.multiply(minetest.facedir_to_dir(node.param2), -1)
		local pusher_pos = vector.add(pos, dir)
		if minetest.get_node(pusher_pos).name == "digistuff:piston_pusher" then
			minetest.remove_node(pusher_pos)
		end
	end,
	digiline = {
		wire = {
			rules = {
				{x = 1, y = 0, z = 0},
				{x =-1, y = 0, z = 0},
				{x = 0, y = 1, z = 0},
				{x = 0, y =-1, z = 0},
				{x = 0, y = 0, z = 1},
				{x = 0, y = 0, z =-1},
			},
		},
		effector = {
			action = function(pos,node,channel,msg)
				local setchan = minetest.get_meta(pos):get_string("channel")
				if channel ~= setchan then return end
				if msg == "retract" then
					retract(pos, node, 0, false, "digilines")
				elseif msg == "retract_sticky" then
					retract(pos, node, 16, false, "digilines")
				elseif msg == "retract_allsticky" then
					retract(pos, node, 16, true, "digilines")
				elseif type(msg) == "table" and msg.action == "retract" then
					local max_pull = 16
					if msg.max == nil then
						max_pull = 0
					elseif type(msg.max) == "number" then
						max_pull = math.max(0, math.min(16, math.floor(msg.max)))
					end
					retract(pos, node, max_pull, msg.allsticky, msg.sound or "digilines")
				end
			end
		},
	},
})

minetest.register_node("digistuff:piston_pusher", {
	description = "Digilines Piston Pusher (you hacker you!)",
	groups = {not_in_creative_inventory = 1},
	is_ground_content = false,
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	tiles = {
		"digistuff_piston_sides.png^[transformR180",
		"digistuff_piston_sides.png",
		"digistuff_piston_sides.png^[transformR90",
		"digistuff_piston_sides.png^[transformR270",
		"digistuff_camera_pole.png",
		"digistuff_camera_pole.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,-0.5,0.5,0.5,-0.3},
			{-0.2,-0.2,-0.3,0.2,0.2,0.5},
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{0,0,0,0,0,0},
		}
	},
	digiline = {
		wire = {
			rules = {
				{x = 1, y = 0, z = 0},
				{x =-1, y = 0, z = 0},
				{x = 0, y = 1, z = 0},
				{x = 0, y =-1, z = 0},
				{x = 0, y = 0, z = 1},
				{x = 0, y = 0, z =-1},
			},
		},
	},
})

mesecon.register_mvps_stopper("digistuff:piston_ext")
mesecon.register_mvps_stopper("digistuff:piston_pusher")

minetest.register_craft({
	output = "digistuff:piston",
	recipe = {
		{"mesecons_pistons:piston_normal_off"},
		{"mesecons_luacontroller:luacontroller0000"},
		{"digilines:wire_std_00000000"},
	},
})

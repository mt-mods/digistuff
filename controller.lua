local digiline_rules = {
	{x =  1,y =  0,z =  0},
	{x = -1,y =  0,z =  0},
	{x =  0,y =  0,z =  1},
	{x =  0,y =  0,z = -1},
	{x =  0,y = -1,z =  0},
	{x =  1,y = -1,z =  0},
	{x = -1,y = -1,z =  0},
	{x =  0,y = -1,z =  1},
	{x =  0,y = -1,z = -1},
}

local players_on_controller = {}

local last_seen_inputs = {}

-- TODO: can we remove this function now?
--       This does still clean up stray entities from crashes
--       or possibly from older versions?
--       Disconnecting from the game while attached also leaves stray
--       entities. Maybe we better handle those instead of using this
--       somewhat expensive search every time some player detaches.
local function removeEntity(pos)
	local entitiesNearby = minetest.get_objects_inside_radius(pos,0.5)
	for _,i in pairs(entitiesNearby) do
		if i:get_luaentity() and i:get_luaentity().name == "digistuff:controller_entity" then
			i:remove()
		end
	end
end

local function process_inputs(pos)
	local meta = minetest.get_meta(pos)
	local hash = minetest.hash_node_position(pos)
	local name = players_on_controller[hash]
	local player = minetest.get_player_by_name(name)
	if minetest.get_node(pos).name ~= "digistuff:controller_programmed" then
		if player then
			player:set_physics_override({speed = 1,jump = 1,})
			player:set_pos(vector.add(pos,vector.new(0.25,0,0.25)))
			minetest.chat_send_player(name, "You are now free to move.")
		end
		last_seen_inputs[name] = nil
		players_on_controller[hash] = nil
		return
	end

	if not player then
		digilines.receptor_send(pos,digiline_rules,meta:get_string("channel"),"player_left")
		minetest.get_meta(pos):set_string("infotext","Digilines Game Controller Ready\n(right-click to use)")
		players_on_controller[hash] = nil
		return
	end

	local inputs = player:get_player_control()
	inputs.pitch = player:get_look_vertical()
	inputs.yaw = player:get_look_horizontal()
	local send_needed = false
	if not last_seen_inputs[name] then
		send_needed = true
	else
		for k,v in pairs(inputs) do
			if v ~= last_seen_inputs[name][k] then
				send_needed = true
				break
			end
		end
	end
	last_seen_inputs[name] = inputs
	if send_needed then
		local channel = meta:get_string("channel")
		inputs = table.copy(inputs)
		inputs.look_vector = player:get_look_dir()
		inputs.name = name
		digilines.receptor_send(pos,digiline_rules,channel,inputs)
	end
end

local function release_player(pos)
	local hash = minetest.hash_node_position(pos)
	local name = players_on_controller[hash]
	local player = minetest.get_player_by_name(name)
	if player then
		local parent = player:get_attach()
		local lua_entity = parent and parent:get_luaentity()
		if lua_entity and lua_entity._is_gamecontroller then
			-- Remove also detaches
			parent:remove()
		end
		minetest.chat_send_player(name, "You are now free to move.")
	end
	-- Shouldn't find any more entities now that above code is fixed
	removeEntity(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("infotext","Digilines Game Controller Ready\n(right-click to use)")
	last_seen_inputs[name] = nil
	players_on_controller[hash] = nil
	digilines.receptor_send(pos,digiline_rules,meta:get_string("channel"),"player_left")
end

local function trap_player(pos,player)
	local hash = minetest.hash_node_position(pos)
	local oldname = players_on_controller[hash]
	local newname = player:get_player_name()
	if oldname and minetest.get_player_by_name(oldname) then
			minetest.chat_send_player(newname,
				"Controller is already occupied by " .. oldname)
			return
	else
		players_on_controller[hash] = newname
		local entity = minetest.add_entity(pos,"digistuff:controller_entity")
		player:set_attach(entity,"",vector.new(0,0,0),vector.new(0,0,0))
		minetest.chat_send_player(newname,"You are now using a digilines game controller. Right-click the controller again to be released.")
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext","Digilines Game Controller\nIn use by: "..newname)
		process_inputs(pos)
	end
end

local function toggle_trap_player(pos,player)
	if players_on_controller[minetest.hash_node_position(pos)] then
		release_player(pos)
	else
		trap_player(pos,player)
	end
end

minetest.register_node("digistuff:controller", {
	description = "Digilines Game Controller",
	tiles = {
		"digistuff_controller_top.png",
		"digistuff_controller_sides.png",
	},
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
				{-0.5,-0.5,-0.5,0.5,-0.45,0.5},
			}
	},
	_digistuff_channelcopier_fieldname = "channel",
	_digistuff_channelcopier_onset = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec","")
		meta:set_string("infotext","Digilines Game Controller Ready\n(right-click to use)")
		minetest.swap_node(pos,{name = "digistuff:controller_programmed",})
	end,
	groups = {cracky = 1,},
	is_ground_content = false,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec","field[channel;Channel;${channel}")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local name = sender:get_player_name()
		if minetest.is_protected(pos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
			minetest.record_protection_violation(pos,name)
			return
		end
		local meta = minetest.get_meta(pos)
		if fields.channel then
			meta:set_string("channel",fields.channel)
			meta:set_string("formspec","")
			meta:set_string("infotext","Digilines Game Controller Ready\n(right-click to use)")
			minetest.swap_node(pos,{name = "digistuff:controller_programmed",})
		end
	end,
	digiline = {
		receptor = {},
		wire = {
			rules = digiline_rules,
		},
	},
})

minetest.register_node("digistuff:controller_programmed", {
	description = "Digilines Game Controller (programmed state - you hacker you!)",
	drop = "digistuff:controller",
	tiles = {
		"digistuff_controller_top.png",
		"digistuff_controller_sides.png",
	},
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
				{-0.5,-0.5,-0.5,0.5,-0.45,0.5},
			}
	},
	_digistuff_channelcopier_fieldname = "channel",
	groups = {cracky = 1,not_in_creative_inventory = 1,},
	is_ground_content = false,
	on_rightclick = function(pos,_,clicker)
		if clicker and clicker:get_player_name() then
			toggle_trap_player(pos,clicker)
		end
	end,
	on_movenode = function(from_pos, to_pos)
		local hashed_from_pos = core.hash_node_position(from_pos)
		local hashed_to_pos = core.hash_node_position(to_pos)
		local name = players_on_controller[hashed_from_pos]
		if not name then
			-- No player attached to this controller.
			return
		end

		local cleanup = false
		local player = core.get_player_by_name(name)
		if not player then
			-- Player has logged off -> cleanup
			cleanup = true
		end
		local parent = player and player:get_attach()
		local lua_entity = parent and parent:get_luaentity()
		if not (lua_entity and lua_entity._is_gamecontroller) then
			-- Player is not attached or failed to get lua entity
			-- or player is now attached to some other entity -> cleanup
			cleanup = true
		end
		if cleanup then
			removeEntity(from_pos)
			players_on_controller[hashed_from_pos] = nil
			last_seen_inputs[name] = nil
			return
		end

		-- Move entity to new location -> player moves along
		-- Jumpdrive will then also attempt to move player and
		-- delete entity at from_pos.
		parent:set_pos(to_pos)
		-- Update cache to new position
		players_on_controller[hashed_to_pos] = name
		players_on_controller[hashed_from_pos] = nil
	end,
	digiline = {
		receptor = {},
		wire = {
			rules = digiline_rules,
		},
		effector = {
			action = function(pos,node,channel,msg)
				local setchannel = minetest.get_meta(pos):get_string("channel")
				if channel ~= setchannel then return end
				if msg == "release" then
					local hash = minetest.hash_node_position(pos)
					if players_on_controller[hash] then
						release_player(pos)
					end
				end
			end,
		},
	},
})

minetest.register_entity("digistuff:controller_entity",{
	initial_properties = {
		visual = "sprite",
		physical = false,
		collisionbox = {0,0,0,0,0,0,},
		textures = {"digistuff_transparent.png",},
	},
	_is_gamecontroller = true,
})

local acc_dtime = 0

minetest.register_globalstep(function(dtime)
	acc_dtime = acc_dtime + dtime
	if acc_dtime < 0.2 then return end
	acc_dtime = 0
	for hash in pairs(players_on_controller) do
		local pos = minetest.get_position_from_hash(hash)
		process_inputs(pos)
	end
end)

minetest.register_lbm({
	name = "digistuff:reset_controllers",
	label = "Reset game controllers to idle",
	nodenames = {"digistuff:controller_programmed"},
	run_at_every_load = true,
	action = function(pos)
		if not players_on_controller[minetest.hash_node_position(pos)] then
			local meta = minetest.get_meta(pos)
			digilines.receptor_send(pos,digiline_rules,meta:get_string("channel"),"player_left")
			meta:set_string("infotext","Digilines Game Controller Ready\n(right-click to use)")
		end
	end,
})

minetest.register_craft({
	output = "digistuff:controller",
	recipe = {
		{"","digistuff:button","",},
		{"digistuff:button","group:wool","digistuff:button",},
		{"","digistuff:button","",},
	},
})

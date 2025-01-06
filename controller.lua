
local FR2D = -180 / math.pi

local S, FS = digistuff.S, digistuff.FS
local sFreeToMove = S("You are now free to move.")
local sReady = S("Digilines Game Controller Ready\n(right-click to use)")

local digiline_rules = {
	{ x =  1, y =  0, z =  0 },
	{ x = -1, y =  0, z =  0 },
	{ x =  0, y =  0, z =  1 },
	{ x =  0, y =  0, z = -1 },
	{ x =  0, y = -1, z =  0 },
	{ x =  1, y = -1, z =  0 },
	{ x = -1, y = -1, z =  0 },
	{ x =  0, y = -1, z =  1 },
	{ x =  0, y = -1, z = -1 },
}

-- Cache of players trapped to game controllers
-- Format: { [position_hash] = player_name, ... }
local players_on_controller = {}
-- Cache of last input tables retrieved with player:get_player_control()
-- plus pitch and yaw fields.
-- Format: { [player_name] = input_table }
local last_seen_inputs = {}

-- This cleans up stray entities from crashes or possibly from older versions?
-- (But only if a player uses the controller at the same location.)
-- This also clears entities of players logging off while trapped.
-- Maybe we can eventually better handle stray entities
-- instead of using this somewhat expensive search every time a player detaches.
local function removeEntity(pos)
	local entitiesNearby = core.get_objects_inside_radius(pos, 0.5)
	local l_ent
	for _, ent in ipairs(entitiesNearby) do
		l_ent = ent:get_luaentity()
		if l_ent and l_ent.name == "digistuff:controller_entity" then
			ent:remove()
		end
	end
end

local function release_player(pos)
	local hash = core.hash_node_position(pos)
	local name = players_on_controller[hash]
	local player = core.get_player_by_name(name)
	if player then
		local parent = player:get_attach()
		local lua_entity = parent and parent:get_luaentity()
		if lua_entity and lua_entity._is_gamecontroller then
			-- Remove also detaches
			parent:remove()
		end
		core.chat_send_player(name, sFreeToMove)
	end
	-- Shouldn't find any more entities now that above code is fixed
	removeEntity(pos)
	local meta = core.get_meta(pos)
	meta:set_string("infotext", sReady)
	last_seen_inputs[name] = nil
	players_on_controller[hash] = nil
	digilines.receptor_send(pos, digiline_rules,
		meta:get_string("channel"), "player_left")
end

local function process_inputs(pos)
	local hash = core.hash_node_position(pos)
	local name = players_on_controller[hash]
	local player = core.get_player_by_name(name)
	if core.get_node(pos).name ~= "digistuff:controller_programmed" then
		if player then
			player:set_physics_override({ speed = 1, jump = 1 })
			player:set_pos(vector.add(pos, vector.new(0.25, 0, 0.25)))
			core.chat_send_player(name, sFreeToMove)
		end
		last_seen_inputs[name] = nil
		players_on_controller[hash] = nil
		return
	end

	local meta = core.get_meta(pos)
	local channel = meta:get_string("channel")
	if not player then
		digilines.receptor_send(pos, digiline_rules, channel, "player_left")
		meta:set_string("infotext", sReady)
		last_seen_inputs[name] = nil
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
		for k, v in pairs(inputs) do
			if v ~= last_seen_inputs[name][k] then
				send_needed = true
				break
			end
		end
	end
	last_seen_inputs[name] = inputs
	if send_needed then
		local inputs_copy = table.copy(inputs)
		inputs_copy.look_vector = player:get_look_dir()
		inputs_copy.name = name
		digilines.receptor_send(pos, digiline_rules, channel, inputs_copy)
		local entity, bone, position = player:get_attach()
		if not entity then
			release_player(pos)
			return
		end

		-- Update direction player is looking.
		player:set_attach(entity, bone, position,
			vector.new(0, inputs.yaw * FR2D, 0))
	end
end

-- Assumes that no other player is trapped at this position
local function trap_player(pos, player)
	local hash = core.hash_node_position(pos)
	local name = player:get_player_name()
	players_on_controller[hash] = name
	local entity = core.add_entity(pos, "digistuff:controller_entity")
	player:set_attach(entity, "", vector.zero(),
		vector.new(0, player:get_look_horizontal() * FR2D, 0))
	core.chat_send_player(name,
		S("You are now using a digilines game controller. " ..
		"Right-click the controller again to be released."))
	core.get_meta(pos):set_string("infotext",
		S("Digilines Game Controller\nIn use by: @1", name))
	process_inputs(pos)
end

local function toggle_trap_player(pos, player)
	local new_name = player:get_player_name()
	local old_name = players_on_controller[core.hash_node_position(pos)]
	if old_name == new_name then
		-- In use by same player -> release
		release_player(pos)
	elseif old_name then
		-- In use by another player -> refuse
		core.chat_send_player(new_name,
			S("Controller is already occupied by @1", old_name))
	else
		-- Not in use -> trap
		trap_player(pos, player)
	end
end

core.register_node("digistuff:controller", {
	description = S("Digilines Game Controller"),
	tiles = {
		"digistuff_controller_top.png",
		"digistuff_controller_sides.png",
	},
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.5, -0.5, 0.5, -0.45, 0.5 },
		},
	},
	_digistuff_channelcopier_fieldname = "channel",
	_digistuff_channelcopier_onset = function(pos)
		local meta = core.get_meta(pos)
		meta:set_string("formspec", "")
		meta:set_string("infotext", sReady)
		core.swap_node(pos, { name = "digistuff:controller_programmed" })
	end,
	groups = { cracky = 1 },
	is_ground_content = false,
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		meta:set_string("formspec",
			"field[channel;" .. FS("Channel") .. ";${channel}")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local name = sender:get_player_name()
		if core.is_protected(pos, name)
			and not core.check_player_privs(name, { protection_bypass = true })
		then
			core.record_protection_violation(pos, name)
			return
		end
		local meta = core.get_meta(pos)
		if fields.channel then
			meta:set_string("channel", fields.channel)
			meta:set_string("formspec", "")
			meta:set_string("infotext", sReady)
			core.swap_node(pos, { name = "digistuff:controller_programmed" })
		end
	end,
	digiline = {
		receptor = {},
		wire = {
			rules = digiline_rules,
		},
	},
})

core.register_node("digistuff:controller_programmed", {
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
			{ -0.5, -0.5, -0.5, 0.5, -0.45, 0.5 },
		},
	},
	_digistuff_channelcopier_fieldname = "channel",
	groups = { cracky = 1, not_in_creative_inventory = 1 },
	is_ground_content = false,
	on_rightclick = function(pos, _, clicker)
		if clicker and clicker:get_player_name() then
			toggle_trap_player(pos, clicker)
		end
	end,
	can_dig = function(pos)
		-- Prevent digging of occupied controllers.
		return not players_on_controller[core.hash_node_position(pos)]
	end,
	on_movenode = function(from_pos, to_pos)
		local hashed_from_pos = core.hash_node_position(from_pos)
		local hashed_to_pos = core.hash_node_position(to_pos)
		local name = players_on_controller[hashed_from_pos]
		if not name then
			-- No player attached to this controller.
			return
		end

		local player = core.get_player_by_name(name)
		local parent = player and player:get_attach()
		local lua_entity = parent and parent:get_luaentity()
		if not (lua_entity and lua_entity._is_gamecontroller) then
			-- Player has logged off -> cleanup
			-- Player is not attached or failed to get lua entity
			-- or player is now attached to some other entity -> cleanup
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
			action = function(pos, node, channel, msg)
				local set_channel = core.get_meta(pos):get_string("channel")
				if channel ~= set_channel then return end

				if msg == "release" then
					local hash = core.hash_node_position(pos)
					if players_on_controller[hash] then
						release_player(pos)
					end
				end
			end,
		},
	},
})

core.register_entity("digistuff:controller_entity", {
	initial_properties = {
		visual = "sprite",
		physical = false,
		collisionbox = { 0, 0, 0, 0, 0, 0 },
		textures = { "digistuff_transparent.png" },
	},
	_is_gamecontroller = true,
})

local acc_dtime = 0

core.register_globalstep(function(dtime)
	acc_dtime = acc_dtime + dtime
	if acc_dtime < 0.2 then return end

	acc_dtime = 0
	for hash in pairs(players_on_controller) do
		local pos = core.get_position_from_hash(hash)
		process_inputs(pos)
	end
end)

core.register_lbm({
	name = "digistuff:reset_controllers",
	label = "Reset game controllers to idle",
	nodenames = { "digistuff:controller_programmed" },
	run_at_every_load = true,
	action = function(pos)
		if not players_on_controller[core.hash_node_position(pos)] then
			local meta = core.get_meta(pos)
			digilines.receptor_send(pos, digiline_rules,
				meta:get_string("channel"), "player_left")
			meta:set_string("infotext", sReady)
		end
	end,
})

-- Used when player dies or leaves the game while trapped.
-- Kinda works indirectly thanks to removeEntity()
local function force_release_player(player)
	local player_name = player:get_player_name()
	for hash, name in pairs(players_on_controller) do
		if name == player_name then
			release_player(core.get_position_from_hash(hash))
			break
		end
	end
end

core.register_on_dieplayer(force_release_player)
core.register_on_leaveplayer(force_release_player)

core.register_craft({
	output = "digistuff:controller",
	recipe = {
		{ "", "digistuff:button", "" },
		{ "digistuff:button", "group:wool", "digistuff:button" },
		{ "", "digistuff:button", "" },
	},
})

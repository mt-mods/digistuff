
local unpack = table.unpack or unpack

local formspec_elements = dofile(minetest.get_modpath("digistuff").."/formspec_elements.lua")

local formspec_version = 6

local function create_element_string(element, values)
	if type(element) == "function" then
		return element(values)
	end
	local new_values = {}
	for i,name in ipairs(element[2]) do
		local value = element[4][i](values[name], element[3][i])
		table.insert(new_values, value)
	end
	return string.format(element[1], unpack(new_values))
end

local function modify_element_string(old, values)
	local e = string.match(old, "^(.-)%[[^[]*%]$")
	local element = formspec_elements[e]
	if type(element) ~= "table" then
		return old  -- No-op for special elements, as there is no format string
	end
	local old_values = {string.match(old, element[5])}
	local new_values = {}
	for i,name in ipairs(element[2]) do
		local value = element[4][i](values[name], old_values[i] or element[3][i])
		table.insert(new_values, value)
	end
	return string.format(element[1], unpack(new_values))
end

local function check_old_command(msg)
	local cmd = msg.command
	if cmd == "lock" then
		return {command = "set", locked = true}
	end
	if cmd == "unlock" then
		return {command = "set", locked = false}
	end
	if cmd == "realcoordinates" then
		return {command = "set", real_coordinates = msg.enabled}
	end
	if string.match(cmd, "^add%a+") then
		msg.element = string.sub(cmd, 4)
		msg.command = "add"
		if msg.image then
			-- Compatibility for old name
			msg.texture_name = msg.image
		end
	end
	return msg
end

local function process_command(meta, data, msg)
	msg = check_old_command(msg)
	local cmd = msg.command

	if cmd == "clear" then
		data = {}

	elseif cmd == "add" then
		local element = formspec_elements[msg.element]
		if element then
			local str = create_element_string(element, msg)
			table.insert(data, str)
		end

	elseif cmd == "insert" then
		local element = formspec_elements[msg.element]
		local index = tonumber(msg.index)
		if element and index and index > 0 then
			local str = create_element_string(element, msg)
			table.insert(data, index, str)
		end

	elseif cmd == "replace" then
		local element = formspec_elements[msg.element]
		local index = tonumber(msg.index)
		if element and index and data[index] then
			local str = create_element_string(element, msg)
			data[index] = str
		end

	elseif cmd == "modify" then
		local index = tonumber(msg.index)
		if index and data[index] then
			local str = modify_element_string(data[index], msg)
			data[index] = str
		end

	elseif cmd == "remove" then
		local index = tonumber(msg.index)
		if index and data[index] then
			table.remove(data, index)
		end

	elseif cmd == "delete" then
		local index = tonumber(msg.index)
		if index and data[index] then
			data[index] = nil
		end

	elseif cmd == "set" then
		if msg.locked ~= nil then
			meta:set_int("locked", msg.locked == false and 0 or 1)
		end
		if msg.no_prepend ~= nil then
			meta:set_int("no_prepend", msg.no_prepend == false and 0 or 1)
		end
		if msg.real_coordinates ~= nil then
			meta:set_int("real_coordinates", msg.real_coordinates == false and 0 or 1)
		end
		if msg.fixed_size ~= nil then
			meta:set_int("fixed_size", msg.fixed_size == false and 0 or 1)
		end
		if type(msg.width) == "number" then
			local value = math.max(1, math.min(100, msg.width))
			meta:set_string("width", string.format("%.4g", value))
		end
		if type(msg.height) == "number" then
			local value = math.max(1, math.min(100, msg.height))
			meta:set_string("height", string.format("%.4g", value))
		end
		if type(msg.focus) == "string" then
			meta:set_string("focus", minetest.formspec_escape(msg.focus))
		end
	end

	return data
end

local function get_data(meta)
	local data = minetest.deserialize(meta:get("data"))
	if data and type(data[1]) == "table" then
		-- Old data, convert to new format
		for i,v in ipairs(data) do
			local element = formspec_elements[v.type]
			data[i] = create_element_string(element, v)
		end
	end
	return data
end

local function create_formspec(meta, data)
	local fs = "formspec_version["..formspec_version.."]"
	local width = tonumber(meta:get_string("width")) or 10
	local height = tonumber(meta:get_string("height")) or 8
	if meta:get_int("fixed_size") == 1 then
		fs = fs.."size["..width..","..height..",true]"
	else
		fs = fs.."size["..width..","..height.."]"
	end
	if meta:get_int("no_prepend") == 1 then
		fs = fs.."no_prepend[]"
	end
	if (meta:get("real_coordinates") or meta:get("realcoordinates")) ~= "1" then
		fs = fs.."real_coordinates[false]"
	end
	local focus = meta:get("focus")
	if focus then
		fs = fs.."set_focus["..focus.."]"
	end
	local data_size = 0
	for i in pairs(data) do
		if i > data_size then
			data_size = i
		end
	end
	for i=1, data_size do
		if data[i] then
			fs = fs..data[i]
		end
	end
	return fs
end

local function update_formspec(pos, meta, data)
	data = data or get_data(meta)
	if not meta:get("init") then
		meta:set_string("formspec", "field[channel;Channel;]")
	elseif not data then
		meta:set_string("formspec", "size[10,8]")
	else
		meta:set_string("formspec", create_formspec(meta, data))
	end
end

local function on_digiline(pos, node, channel, msg)
	if type(msg) ~= "table" then
		return
	end
	local meta = minetest.get_meta(pos)
	if channel ~= meta:get_string("channel") then
		return
	end
	local data = get_data(meta) or {}
	if type(msg.command) == "string" then
		data = process_command(meta, data, msg)
	else
		for _,v in ipairs(msg) do
			if type(v) == "table" and type(v.command) == "string" then
				data = process_command(meta, data, v)
			end
		end
	end
	meta:set_string("data", minetest.serialize(data))
	update_formspec(pos, meta, data)
end

local function on_receive_fields(pos, _, fields, player)
	local meta = minetest.get_meta(pos)
	local name = player:get_player_name()
	if meta:get_int("locked") == 1 and minetest.is_protected(pos, name) then
		minetest.chat_send_player(name, "You are not authorized to use this screen.")
		return
	end
	if not meta:get("init") and fields.channel then
		meta:set_string("channel", fields.channel)
		meta:set_int("init", 1)
		update_formspec(pos, meta)
	else
		local channel = meta:get_string("channel")
		fields.clicker = name
		digilines.receptor_send(pos, digilines.rules.default, channel, fields)
	end
end

minetest.register_node("digistuff:touchscreen", {
	description = "Digilines Touchscreen",
	groups = {cracky = 3},
	is_ground_content = false,
	tiles = {
		"digistuff_panel_back.png",
		"digistuff_panel_back.png",
		"digistuff_panel_back.png",
		"digistuff_panel_back.png",
		"digistuff_panel_back.png",
		"digistuff_ts_front.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, 0.4, 0.5, 0.5, 0.5}
		}
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		update_formspec(pos, meta)
	end,
	on_receive_fields = on_receive_fields,
	digilines = {
		receptor = {},
		effector = {
			action = on_digiline
		}
	},
	_digistuff_channelcopier_fieldname = "channel",
	_digistuff_channelcopier_onset = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("init", 1)
		update_formspec(pos, meta)
	end,
})

minetest.register_craft({
	output = "digistuff:touchscreen",
	recipe = {
		{"mesecons_luacontroller:luacontroller0000", "default:glass", "default:glass"},
		{"default:glass", "digilines:lcd", "default:glass"},
		{"default:glass", "default:glass", "default:glass"}
	}
})

minetest.register_alias("digistuff:advtouchscreen", "digistuff:touchscreen")

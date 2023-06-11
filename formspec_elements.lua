
-- `minetest.formspec_escape` with option to not escape commas
local function fs_escape(text, is_list)
	if text ~= nil then
		text = string.gsub(text, "\\", "\\\\")
		text = string.gsub(text, "%]", "\\]")
		text = string.gsub(text, "%[", "\\[")
		text = string.gsub(text, ";", "\\;")
		if not is_list then
			text = string.gsub(text, ",", "\\,")
		end
	end
	return text
end

local function num(value, default_value)
	if type(value) == "string" then
		value = tonumber(value)
	end
	if type(value) ~= "number" then
		return default_value
	end
	return string.format("%s", math.floor(value * 1000) / 1000)
end

local function str(value, default_value)
	if type(value) ~= "string" then
		return default_value
	end
	return fs_escape(value)
end

local function bool(value, default_value)
	if value == "true" or value == "false" then
		return value
	end
	if type(value) ~= "boolean" then
		return default_value
	end
	return value and "true" or "false"
end

local function list(value, default_value)
	if type(value) == "string" then
		return fs_escape(value, true)
	end
	if type(value) ~= "table" or #value < 1 then
		return default_value
	end
	local new_list = {}
	for _,v in ipairs(value) do
		if type(v) == "string" then
			table.insert(new_list, fs_escape(v))
		end
	end
	if #new_list < 1 then
		return default_value
	end
	return table.concat(new_list, ",")
end

local function middle(value, default_value)  -- Only for `background9`
	if type(value) == "number" then
		return string.format("%i", value)
	end
	if type(value) ~= "string" then
		return default_value
	end
	if string.match(value, "^%-?%d+$") or string.match(value, "^%-?%d+,%-?%d+$")
			or string.match(value, "^%-?%d+,%-?%d+,%-?%d+,%-?%d+$") then
		return value
	end
	return default_value
end

local function fullscreen(value, default_value)  -- Only for `bgcolor`
	if type(value) == "boolean" then
		return value and "true" or "false"
	end
	if value == "true" or value == "false"
			or value == "both" or value == "neither" then
		return value
	end
	return default_value
end

local function prop(value, default_value)  -- Only for `stlye` and `style_type`
	if type(value) ~= "table" or next(value) == nil then
		return default_value
	end
	local new_prop = {}
	for k,v in pairs(value) do
		if type(k) == "string" then
			k = fs_escape(k).."="
			if type(v) == "string" then
				table.insert(new_prop, k..fs_escape(v, true))
			elseif type(v) == "number" then
				table.insert(new_prop, k..num(v))
			elseif type(v) == "boolean" then
				table.insert(new_prop, k..bool(v))
			end
		end
	end
	return table.concat(new_prop, ";")
end


local formspec_elements = {
	tooltip = {
		"tooltip[%s;%s;%s;%s]",
		{"element_name", "tooltip_text", "bgcolor", "fontcolor"},
		{"button", "tooltip", "#303030", "#ffffff"},
		{str, str, str, str},
	},
	tooltip_area = {
		"tooltip[%s,%s;%s,%s;%s;%s;%s]",
		{"X", "Y", "W", "H", "tooltip_text", "bgcolor", "fontcolor"},
		{"0", "0", "100", "100", "tooltip area", "#303030", "#ffffff"},
		{num, num, num, num, str, str, str},
	},
	image = {
		"image[%s,%s;%s,%s;%s;%s]",
		{"X", "Y", "W", "H", "texture_name", "middle"},
		{"0", "0", "1", "1", "default_dirt.png", ""},
		{num, num, num, num, str, middle}
	},
	animated_image = {
		"animated_image[%s,%s;%s,%s;%s;%s;%s;%s;%s;%s]",
		{"X", "Y", "W", "H", "name", "texture_name", "frame_count", "frame_duration", "frame_start", "middle"},
		{"0", "0", "1", "1", "animated_image", "default_lava_flowing_animated.png", "16", "200", "1", ""},
		{num, num, num, num, str, str, num, num, num, middle}
	},
	model = {
		"model[%s,%s;%s,%s;%s;%s;%s;%s,%s;%s;%s;0,0]",
		{"X", "Y", "W", "H", "name", "mesh", "textures", "rotation_x", "rotation_y", "continuous", "mouse_control"},
		{"0", "0", "2", "2", "model", "character.b3d", "character.png", "0", "0", "", ""},
		{num, num, num, num, str, str, list, num, num, bool, bool}
	},
	item_image = {
		"item_image[%s,%s;%s,%s;%s]",
		{"X", "Y", "W", "H", "item_name"},
		{"0", "0", "1", "1", "default:dirt_with_grass"},
		{num, num, num, num, str}
	},
	bgcolor = {
		"bgcolor[%s;%s;%s]",
		{"bgcolor", "fullscreen", "fbgcolor"},
		{"#ffffff", "", ""},
		{str, fullscreen, str}
	},
	background = {
		"background[%s,%s;%s,%s;%s;%s]",
		{"X", "Y", "W", "H", "texture_name", "auto_clip"},
		{"0", "0", "0", "0", "digistuff_ts_bg.png", "true"},
		{num, num, num, num, str, bool}
	},
	background9 = {
		"background9[%s,%s;%s,%s;%s;%s;%s]",
		{"X", "Y", "W", "H", "texture_name", "auto_clip", "middle"},
		{"0", "0", "0", "0", "digistuff_ts_bg.png", "true", "3"},
		{num, num, num, num, str, bool, middle}
	},
	pwdfield = {
		"pwdfield[%s,%s;%s,%s;%s;%s]",
		{"X", "Y", "W", "H", "name", "label"},
		{"0", "0", "3", "0.8", "pwdfield", ""},
		{num, num, num, num, str, str}
	},
	field = {
		"field[%s,%s;%s,%s;%s;%s;%s]",
		{"X", "Y", "W", "H", "name", "label", "default"},
		{"0", "0", "3", "0.8", "field", "field", ""},
		{num, num, num, num, str, str, str}
	},
	field_close_on_enter = {
		"field_close_on_enter[%s;%s]",
		{"name", "close_on_enter"},
		{"field", "true"},
		{str, bool}
	},
	textarea = {
		"textarea[%s,%s;%s,%s;%s;%s;%s]",
		{"X", "Y", "W", "H", "name", "label", "default"},
		{"0", "0", "4", "3", "textarea", "", ""},
		{num, num, num, num, str, str, str}
	},
	label = {
		"label[%s,%s;%s]",
		{"X", "Y", "label"},
		{"0", "0", "label"},
		{num, num, str}
	},
	hypertext = {
		"hypertext[%s,%s;%s,%s;%s;%s]",
		{"X", "Y", "W", "H", "name", "text"},
		{"0", "0", "4", "3", "hypertext", "<i>hypertext</i>"},
		{num, num, num, num, str, str}
	},
	vertlabel = {
		"vertlabel[%s,%s;%s]",
		{"X", "Y", "label"},
		{"0", "0", "vertlabel"},
		{num, num, str}
	},
	button = {
		"button[%s,%s;%s,%s;%s;%s]",
		{"X", "Y", "W", "H", "name", "label"},
		{"0", "0", "3", "0.8", "button", "button"},
		{num, num, num, num, str, str}
	},
	image_button = {
		"image_button[%s,%s;%s,%s;%s;%s;%s;%s;%s;%s]",
		{"X", "Y", "W", "H", "texture_name", "name", "label", "noclip", "drawborder", "pressed_texture_name"},
		{"0", "0", "1", "1", "default_stone_block.png", "image_button", "button", "", "", ""},
		{num, num, num, num, str, str, str, bool, bool, str}
	},
	item_image_button = {
		"item_image_button[%s,%s;%s,%s;%s;%s;%s]",
		{"X", "Y", "W", "H", "item_name", "name", "label"},
		{"0", "0", "1", "1", "default:stone_block", "item_image_button", ""},
		{num, num, num, num, str, str, str}
	},
	button_exit = {
		"button_exit[%s,%s;%s,%s;%s;%s]",
		{"X", "Y", "W", "H", "name", "label"},
		{"0", "0", "3", "0.8", "button_exit", "button"},
		{num, num, num, num, str, str}
	},
	image_button_exit = {
		"image_button_exit[%s,%s;%s,%s;%s;%s;%s]",
		{"X", "Y", "W", "H", "texture_name", "name", "label"},
		{"0", "0", "1", "1", "default_mese_block.png", "image_button_exit", "button"},
		{num, num, num, num, str, str, str}
	},
	textlist = {
		"textlist[%s,%s;%s,%s;%s;%s;%s;%s]",
		{"X", "Y", "W", "H", "name", "listelements", "selected_id", "transparent"},
		{"0", "0", "4", "3", "textlist", "a,b,c", "0", "false"},
		{num, num, num, num, str, list, num, bool}
	},
	tabheader = {
		"tabheader[%s,%s;%s;%s;%s;%s;%s]",
		{"X", "Y", "name", "captions", "current_tab", "transparent", "draw_border"},
		{"0", "0", "tabheader", "a,b,c", "0", "false", "false"},
		{num, num, str, list, num, bool, bool}
	},
	box = {
		"box[%s,%s;%s,%s;%s]",
		{"X", "Y", "W", "H", "color"},
		{"0", "0", "1", "1", "#ffffff"},
		{num, num, num, num, str}
	},
	dropdown = {
		"dropdown[%s,%s;%s,%s;%s;%s;%s;%s]",
		{"X", "Y", "W", "H", "name", "choices", "selected_id", "index_event"},
		{"0", "0", "3", "0.8", "dropdown", "a,b,c", "0", "false"},
		{num, num, num, num, str, list, num, bool}
	},
	checkbox = {
		"checkbox[%s,%s;%s;%s;%s]",
		{"X", "Y", "name", "label", "selected"},
		{"0", "0", "checkbox", "checkbox", "false"},
		{num, num, str, str, bool}
	},
	style = {
		"style[%s;%s]",
		{"selectors", "properties"},
		{"", ""},
		{list, prop}
	},
	style_type = {
		"style_type[%s;%s]",
		{"selectors", "properties"},
		{"", ""},
		{list, prop}
	},
}

-- Create un-format strings for modifying elements
for _,element in pairs(formspec_elements) do
	local s = string.gsub(element[1], "%%s", "(.*)")
	s = string.gsub(s, "%[", "%%[")
	s = string.gsub(s, "%]", "%%]")
	element[5] = "^"..s.."$"
end


local table_options = {
	color = str,
	background = str,
	border = bool,
	highlight = str,
	highlight_text = str,
	opendepth = num
}

local function column(value)
	if type(value) == "string" then
		return fs_escape(value, true)
	end
	if type(value) ~= "table" or type(value.type) ~= "string" then
		return
	end
	local new_column = {str(value.type)}
	for k,v in pairs(value) do
		if type(k) == "string" and k ~= "type" then
			k = fs_escape(k).."="
			if type(v) == "string" then
				table.insert(new_column, k..fs_escape(v, true))
			elseif type(v) == "number" then
				table.insert(new_column, k..string.format("%.4g", v))
			end
		end
	end
	return table.concat(new_column, ",")
end

formspec_elements.table = function(values)
	local tbl = ""
	local name = str(values.name, "table")
	local cells = list(values.cells, "a,b,c")
	for v,d in pairs({X = 0, Y = 0, W = 4, H = 3, selected_id = 0}) do
		if type(values[v]) ~= "number" then
			values[v] = d
		end
	end
	local options = {}
	for v,f in pairs(table_options) do
		local value = f(values[v])
		if value ~= nil then
			table.insert(options, v.."="..value)
		end
	end
	if #options > 0 then
		tbl = tbl.."tableoptions["..table.concat(options, ";").."]"
	end
	local columns = {}
	if type(values.columns) == "table" then
		for _,v in ipairs(values.columns) do
			table.insert(columns, column(v, true))
		end
	end
	if #columns > 0 then
		tbl = tbl.."tablecolumns["..table.concat(columns, ";").."]"
	end
	return tbl..string.format("table[%s,%s;%s,%s;%s;%s;%s]",
		values.X, values.Y, values.W, values.H, name, cells, values.selected_id)
end


formspec_elements.item_grid = function(values)
	for v,d in pairs({X = 0, Y = 0, W = 1, H = 1, spacing = 0, size = 1, offset = 1}) do
		if type(values[v]) ~= "number" then
			values[v] = d
		end
	end
	local name = str(values.name, "grid").."_"
	local items = type(values.items) == "table" and values.items or {}
	local offset = math.max(1, math.floor(values.offset)) - 1
	local x, y, n, item = values.X, values.Y, 1
	local grid = {}
	for _=1, values.H do
		for _=1, values.W do
			item = items[n + offset]
			if type(item) ~= "string" then
				return table.concat(grid)
			end
			item = string.match(item, "^[^ %[%]\\,;]* ?%d* ?%d*")
			if values.interactable ~= false then
				grid[n] = string.format("item_image_button[%s,%s;%s,%s;%s;%s;]",
					x, y, values.size, values.size, item, name..n)
			else
				grid[n] = string.format("item_image[%s,%s;%s,%s;%s]",
					x, y, values.size, values.size, item)
			end
			n = n + 1
			x = x + values.size + values.spacing
		end
		x = values.X
		y = y + values.size + values.spacing
	end
	return table.concat(grid)
end

return formspec_elements

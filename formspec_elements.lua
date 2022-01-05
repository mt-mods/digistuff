
local function num(value, default_value)
	if type(value) ~= "number" then
		return default_value
	end
	return string.format("%.4g", value)
end

local function str(value, default_value)
	if type(value) ~= "string" then
		return default_value
	end
	return minetest.formspec_escape(value)
end

local function list(value, default_value)
	if type(value) ~= "table" then
		if type(value) == "string" then
			return minetest.formspec_escape(value)
		end
		return default_value
	end
	if #value < 1 then
		return default_value
	end
	local new_list = {}
	for _,v in ipairs(value) do
		if type(v) == "string" then
			new_list:insert(minetest.formspec_escape(v))
		end
	end
	if #new_list < 1 then
		return default_value
	end
	return new_list:concat(",")
end

local function bool(value, default_value)
	if type(value) ~= "boolean" then
		if value == "true" or value == "false" then
			return value
		end
		return default_value
	end
	return value and "true" or "false"
end

local formspec_elements = {
	tooltip = {
		"tooltip[%s;%s;%s;%s]",
		{"element_name", "tooltip_text", "bgcolor", "fontcolor"},
		{"button", "tooltip", "#303030", "#ffffff"},
		{str, str, str, str},
	},
	tooltip_area = {
		"tooltip[%s;%s;%s;%s]",
		{"X", "Y", "W", "H", "tooltip_text", "bgcolor", "fontcolor"},
		{"0", "0", "100", "100", "tooltip area", "#303030", "#ffffff"},
		{num, num, num, num, str, str, str},
	},
	image = {
		"image[%s,%s;%s,%s;%s]",
		{"X", "Y", "W", "H", "texture_name"},
		{"0", "0", "1", "1", "default_dirt.png^default_grass_side.png"},
		{num, num, num, num, str}
	},
	animated_image = {
		"animated_image[%s,%s;%s,%s;%s;%s;%s;%s;%s]",
		{"X", "Y", "W", "H", "name", "texture_name", "frame_count", "frame_duration", "frame_start"},
		{"0", "0", "1", "1", "animated_image", "default_lava_flowing_animated.png", "16", "200", "1"},
		{num, num, num, num, str, str, num, num, num}
	},
	model = {
		"model[%s,%s;%s,%s;%s;%s;%s;%s,%s;%s;%s;]",
		{"X", "Y", "W", "H", "name", "mesh", "textures", "rotation_x", "rotation_y", "continuous", "mouse_control"},
		{"0", "0", "2", "2", "model", "torch_floor.obj", "default_torch_on_floor.png", "0", "0", "", ""},
		{num, num, num, num, str, str, list, num, num, bool, bool}
	},
	item_image = {
		"item_image[%s,%s;%s,%s;%s]",
		{"X", "Y", "W", "H", "item_name"},
		{"0", "0", "1", "1", "default:dirt_with_grass"},
		{num, num, num, num, str}
	},
	background = {
		"background[%s,%s;%s,%s;%s;%s]",
		{"X", "Y", "W", "H", "texture_name", "auto_clip"},
		{"0", "0", "0", "0", "digistuff_ts_bg.png", "true"},
		{num, num, num, num, str, bool}
	},
	pwdfield = {
		"field[%s,%s;%s,%s;%s;%s]",
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
		{"0", "0", "4", "3", "hypertext", "hypertext"},
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
		"image_button[%s,%s;%s,%s;%s;%s;%s]",
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
		"dropdown[%s,%s;%s,%s;%s;%s,%s;%s;%s]",
		{"X", "Y", "W", "H", "name", "listelements", "selected_id", "index_event"},
		{"0", "0", "3", "0.8", "dropdown", "a,b,c", "0", "false"},
		{num, num, num, num, str, list, num, bool}
	},
	checkbox = {
		"checkbox[%s,%s;%s;%s;%s]",
		{"X", "Y", "name", "label", "selected"},
		{"0", "0", "checkbox", "checkbox", "false"},
		{num, num, str, str, bool}
	},
}

return formspec_elements

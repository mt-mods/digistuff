digibutton = {}

digibutton.button_turnoff = function (pos)
	local node = minetest.get_node(pos)
	if node.name=="digibutton:button_on" then --has not been dug
		minetest.swap_node(pos, {name = "digibutton:button_off", param2=node.param2})
		minetest.sound_play("mesecons_button_pop", {pos=pos})
	end
end

minetest.register_node("digibutton:digimese", {
	description = "Digimese",
	tiles = {"digimese.png"},
	paramtype = "light",
	light_source = 3,
	groups = {cracky = 3, level = 2},
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	digiline = { wire = { rules = {
	{x = 1, y = 0, z = 0},
	{x =-1, y = 0, z = 0},
	{x = 0, y = 1, z = 0},
	{x = 0, y =-1, z = 0},
	{x = 0, y = 0, z = 1},
	{x = 0, y = 0, z =-1}}}}
})

minetest.register_node("digibutton:button", {
	drawtype = "nodebox",
	tiles = {
	"digibutton_sides.png",
	"digibutton_sides.png",
	"digibutton_sides.png",
	"digibutton_sides.png",
	"digibutton_sides.png",
	"digibutton_off.png"
	},
	paramtype = "light",
	paramtype2 = "facedir",
	legacy_wallmounted = true,
	walkable = false,
	sunlight_propagates = true,
	selection_box = {
	type = "fixed",
		fixed = { -6/16, -6/16, 5/16, 6/16, 6/16, 8/16 }
	},
	node_box = {
		type = "fixed",
		fixed = {
		{ -6/16, -6/16, 6/16, 6/16, 6/16, 8/16 },	-- the thin plate behind the button
		{ -4/16, -2/16, 4/16, 4/16, 2/16, 6/16 }	-- the button itself
	}
	},
	digiline = 
	{
		receptor = {}
	},
	groups = {dig_immediate=2},
	description = "Digilines Button",
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec","size[8,4;]field[1,1;6,2;channel;Channel;${channel}]field[1,2;6,2;msg;Message;${msg}]button_exit[2.25,3;3,1;submit;Save]")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		if fields.channel and fields.msg and fields.channel ~= "" and fields.msg ~= "" then
			meta:set_string("channel",fields.channel)
			meta:set_string("msg",fields.msg)
			meta:set_string("formspec","")
			minetest.swap_node(pos, {name = "digibutton:button_off", param2=minetest.get_node(pos).param2})
		else
			minetest.chat_send_player(sender:get_player_name(),"Channel and message must both be set!")
		end
	end,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("digibutton:button_off", {
	drawtype = "nodebox",
	tiles = {
	"digibutton_sides.png",
	"digibutton_sides.png",
	"digibutton_sides.png",
	"digibutton_sides.png",
	"digibutton_sides.png",
	"digibutton_off.png"
	},
	paramtype = "light",
	paramtype2 = "facedir",
	legacy_wallmounted = true,
	walkable = false,
	sunlight_propagates = true,
	selection_box = {
	type = "fixed",
		fixed = { -6/16, -6/16, 5/16, 6/16, 6/16, 8/16 }
	},
	node_box = {
		type = "fixed",
		fixed = {
		{ -6/16, -6/16, 6/16, 6/16, 6/16, 8/16 },	-- the thin plate behind the button
		{ -4/16, -2/16, 4/16, 4/16, 2/16, 6/16 }	-- the button itself
	}
	},
	digiline = 
	{
		receptor = {}
	},
	groups = {dig_immediate=2, not_in_creative_inventory=1},
	drop = "digibutton:button",
	description = "Digilines Button (off state - you hacker you!)",
	on_rightclick = function (pos, node, clicker)
		local meta = minetest.get_meta(pos)
		digiline:receptor_send(pos, digiline.rules.default, meta:get_string("channel"), meta:get_string("msg"))
		minetest.swap_node(pos, {name = "digibutton:button_on", param2=node.param2})
		minetest.sound_play("mesecons_button_push", {pos=pos})
		minetest.after(1, digibutton.button_turnoff, pos)
	end,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("digibutton:button_on", {
	drawtype = "nodebox",
	tiles = {
		"digibutton_sides.png",
		"digibutton_sides.png",
		"digibutton_sides.png",
		"digibutton_sides.png",
		"digibutton_sides.png",
		"digibutton_on.png"
		},
	paramtype = "light",
	paramtype2 = "facedir",
	legacy_wallmounted = true,
	walkable = false,
	light_source = default.LIGHT_MAX-7,
	sunlight_propagates = true,
	selection_box = {
		type = "fixed",
		fixed = { -6/16, -6/16, 5/16, 6/16, 6/16, 8/16 }
	},
	node_box = {
	type = "fixed",
	fixed = {
		{ -6/16, -6/16,  6/16, 6/16, 6/16, 8/16 },
		{ -4/16, -2/16, 11/32, 4/16, 2/16, 6/16 }
	}
    	},
	digiline = 
	{
		receptor = {}
	},
	groups = {dig_immediate=2, not_in_creative_inventory=1},
	drop = 'digibutton:button',
	description = "Digilines Button (on state - you hacker you!)",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	output = "digibutton:digimese",
	recipe = {
		{"digilines:wire_std_00000000","digilines:wire_std_00000000","digilines:wire_std_00000000"},
		{"digilines:wire_std_00000000","default:mese","digilines:wire_std_00000000"},
		{"digilines:wire_std_00000000","digilines:wire_std_00000000","digilines:wire_std_00000000"}
	}
})

minetest.register_craft({
	output = "digibutton:button",
	recipe = {
		{"mesecons_button:button_off"},
		{"mesecons_luacontroller:luacontroller0000"},
		{"digilines:wire_std_00000000"}
	}
})

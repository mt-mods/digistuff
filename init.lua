digistuff = {}

digistuff.update_panel_formspec = function (pos,dispstr)
	local meta = minetest.get_meta(pos)
	local fs = "size[10,8]"..
		"background[0,0;0,0;digistuff_panel_bg.png;true]"..
		"label[0,0;%s]"..
		"image_button[2,4.5;1,1;digistuff_adwaita_go-up.png;up;]"..
		"image_button[1,5;1,1;digistuff_adwaita_go-previous.png;left;]"..
		"image_button[3,5;1,1;digistuff_adwaita_go-next.png;right;]"..
		"image_button[2,5.5;1,1;digistuff_adwaita_go-down.png;down;]"..
		"image_button[1,6.5;1,1;digistuff_adwaita_edit-undo.png;back;]"..
		"image_button[3,6.5;1,1;digistuff_adwaita_emblem-default.png;enter;]"..
		"field[6,5.75;2,1;channel;Channel;${channel}]"..
		"button[8,5.5;1,1;savechan;Set]"
	fs = fs:format(minetest.formspec_escape(dispstr)):gsub("|","\n")
	meta:set_string("formspec",fs)
end

digistuff.panel_on_digiline_receive = function (pos, node, channel, msg)
	local meta = minetest.get_meta(pos)
	local setchan = meta:get_string("channel")
	if channel ~= setchan then return end
	if type(msg) ~= "string" then return end
	digistuff.update_panel_formspec(pos,msg)
end

digistuff.panel_on_receive_fields = function(pos, formname, fields, sender)
	local meta = minetest.get_meta(pos)
	local setchan = meta:get_string("channel")
	if fields.savechan then
		meta:set_string("channel",fields.channel)
		local helpmsg = "Channel has been set. Waiting for data..."
		digistuff.update_panel_formspec(pos,helpmsg)
	elseif fields.up then
		digiline:receptor_send(pos, digiline.rules.default, setchan, "up")
	elseif fields.down then
		digiline:receptor_send(pos, digiline.rules.default, setchan, "down")
	elseif fields.left then
		digiline:receptor_send(pos, digiline.rules.default, setchan, "left")
	elseif fields.right then
		digiline:receptor_send(pos, digiline.rules.default, setchan, "right")
	elseif fields.back then
		digiline:receptor_send(pos, digiline.rules.default, setchan, "back")
	elseif fields.enter then
		digiline:receptor_send(pos, digiline.rules.default, setchan, "enter")
	end
end

digistuff.button_turnoff = function (pos)
	local node = minetest.get_node(pos)
	if node.name=="digistuff:button_on" then --has not been dug
		minetest.swap_node(pos, {name = "digistuff:button_off", param2=node.param2})
		minetest.sound_play("mesecons_button_pop", {pos=pos})
	end
end

minetest.register_node("digistuff:digimese", {
	description = "Digimese",
	tiles = {"digistuff_digimese.png"},
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

minetest.register_node("digistuff:button", {
	drawtype = "nodebox",
	tiles = {
	"digistuff_digibutton_sides.png",
	"digistuff_digibutton_sides.png",
	"digistuff_digibutton_sides.png",
	"digistuff_digibutton_sides.png",
	"digistuff_digibutton_sides.png",
	"digistuff_digibutton_off.png"
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

minetest.register_node("digistuff:button_off", {
	drawtype = "nodebox",
	tiles = {
	"digistuff_digibutton_sides.png",
	"digistuff_digibutton_sides.png",
	"digistuff_digibutton_sides.png",
	"digistuff_digibutton_sides.png",
	"digistuff_digibutton_sides.png",
	"digistuff_digibutton_off.png"
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
	drop = "digistuff:button",
	description = "Digilines Button (off state - you hacker you!)",
	on_rightclick = function (pos, node, clicker)
		local meta = minetest.get_meta(pos)
		digiline:receptor_send(pos, digiline.rules.default, meta:get_string("channel"), meta:get_string("msg"))
		minetest.swap_node(pos, {name = "digistuff:button_on", param2=node.param2})
		minetest.sound_play("mesecons_button_push", {pos=pos})
		minetest.after(0.5, digistuff.button_turnoff, pos)
	end,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("digistuff:button_on", {
	drawtype = "nodebox",
	tiles = {
		"digistuff_digibutton_sides.png",
		"digistuff_digibutton_sides.png",
		"digistuff_digibutton_sides.png",
		"digistuff_digibutton_sides.png",
		"digistuff_digibutton_sides.png",
		"digistuff_digibutton_on.png"
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
	drop = 'digistuff:button',
	on_rightclick = function (pos, node, clicker)
		local meta = minetest.get_meta(pos)
		digiline:receptor_send(pos, digiline.rules.default, meta:get_string("channel"), meta:get_string("msg"))
		minetest.sound_play("mesecons_button_push", {pos=pos})
	end,
	description = "Digilines Button (on state - you hacker you!)",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	output = "digistuff:digimese",
	recipe = {
		{"digilines:wire_std_00000000","digilines:wire_std_00000000","digilines:wire_std_00000000"},
		{"digilines:wire_std_00000000","default:mese","digilines:wire_std_00000000"},
		{"digilines:wire_std_00000000","digilines:wire_std_00000000","digilines:wire_std_00000000"}
	}
})

minetest.register_craft({
	output = "digistuff:button",
	recipe = {
		{"mesecons_button:button_off"},
		{"mesecons_luacontroller:luacontroller0000"},
		{"digilines:wire_std_00000000"}
	}
})

minetest.register_alias("digibutton:button","digistuff:button")
minetest.register_alias("digibutton:button_off","digistuff:button_off")
minetest.register_alias("digibutton:button_on","digistuff:button_on")
minetest.register_alias("digibutton:digimese","digistuff:digimese")

minetest.register_node("digistuff:detector", {
	tiles = {
	"digistuff_digidetector.png"
	},
	digiline = 
	{
		receptor = {}
	},
	groups = {cracky=2},
	description = "Digilines Player Detector",
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec","size[8,4;]field[1,1;6,2;channel;Channel;${channel}]field[1,2;6,2;radius;Radius;${radius}]button_exit[2.25,3;3,1;submit;Save]")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		if fields.channel then meta:set_string("channel",fields.channel) end
		if fields.msg then meta:set_string("msg",fields.msg) end
		if fields.radius then meta:set_string("radius",fields.radius) end
	end,
	sounds = default.node_sound_stone_defaults()
})

minetest.register_abm({
	nodenames = {"digistuff:detector"},
	interval = 1.0,
	chance = 1,
	action = function(pos)
			local meta = minetest.get_meta(pos)
			local channel = meta:get_string("channel")
			local radius = meta:get_string("radius")
			local found_any = false
			local players_found = {}
			if not radius or not tonumber(radius) or tonumber(radius) < 1 or tonumber(radius) > 10 then radius = 6 end
			local objs = minetest.get_objects_inside_radius(pos, radius)
			if objs then
				local _,obj
				for _,obj in ipairs(objs) do
					if obj:is_player() then
						table.insert(players_found,obj:get_player_name())
						found_any = true
					end
				end
				if found_any then
					digiline:receptor_send(pos, digiline.rules.default, channel, players_found)
				end
			end
		end
})

minetest.register_node("digistuff:panel", {
	description = "Digilines Control Panel",
	groups = {cracky=3},
	on_construct = function(pos)
		local helpmsg = "Please set a channel."
		digistuff.update_panel_formspec(pos,helpmsg)
	end,
	drawtype = "nodebox",
	tiles = {
		"digistuff_panel_back.png",
		"digistuff_panel_back.png",
		"digistuff_panel_back.png",
		"digistuff_panel_back.png",
		"digistuff_panel_back.png",
		"digistuff_panel_front.png"
		},
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.5, 0.4, 0.5, 0.5, 0.5 }
		}
    	},
	on_receive_fields = digistuff.panel_on_receive_fields,
	digiline = 
	{
		receptor = {},
		effector = {
			action = digistuff.panel_on_digiline_receive
		},
	},
})

minetest.register_craft({
	output = "digistuff:detector",
	recipe = {
		{"mesecons_detector:object_detector_off"},
		{"mesecons_luacontroller:luacontroller0000"},
		{"digilines:wire_std_00000000"}
	}
})

minetest.register_craft({
	output = "digistuff:panel",
	recipe = {
		{"","digistuff:button",""},
		{"digistuff:button","digilines:lcd","digistuff:button"},
		{"","digistuff:button",""}
	}
})

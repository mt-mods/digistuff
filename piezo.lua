digistuff.sounds_playing = {}

local function stop_sounds(pos_hash)
	if digistuff.sounds_playing[pos_hash] then
		minetest.sound_stop(digistuff.sounds_playing[pos_hash])
		digistuff.sounds_playing[pos_hash] = nil
	end
end

local function play_sound(pos, pos_hash, sound, loop)
	stop_sounds(pos_hash)
	local params = {pos = pos, gain = 0.2, max_hear_distance = 16, loop = loop}
	if loop then
		digistuff.sounds_playing[pos_hash] = minetest.sound_play(sound, params)
	else
		minetest.sound_play(sound, params)
	end
end

minetest.register_node("digistuff:piezo", {
	description = "Digilines Piezoelectric Beeper",
	groups = {cracky = 3},
	is_ground_content = false,
	on_construct = function(pos)
		minetest.get_meta(pos):set_string("formspec", "field[channel;Channel;${channel}")
	end,
	on_destruct = function(pos)
		stop_sounds(minetest.hash_node_position(pos))
	end,
	_digistuff_channelcopier_fieldname = "channel",
	tiles = {
		"digistuff_piezo_top.png",
		"digistuff_piezo_sides.png",
		"digistuff_piezo_sides.png",
		"digistuff_piezo_sides.png",
		"digistuff_piezo_sides.png",
		"digistuff_piezo_sides.png"
	},
	on_receive_fields = function(pos, formname, fields, sender)
		if minetest.is_protected(pos, sender:get_player_name()) then return end
		if fields.channel then
			minetest.get_meta(pos):set_string("channel", fields.channel)
		end
	end,
	digiline = {
		receptor = {},
		effector = {
			action = function(pos, node, channel, msg)
				local setchan = minetest.get_meta(pos):get_string("channel")
				if channel ~= setchan then return end
				local pos_hash = minetest.hash_node_position(pos)
				if msg == "shortbeep" then
					play_sound(pos, pos_hash, "digistuff_piezo_short_single")
				elseif msg == "longbeep" then
					play_sound(pos, pos_hash, "digistuff_piezo_long_single")
				elseif msg == "fastrepeat" then
					play_sound(pos, pos_hash, "digistuff_piezo_fast_repeat", true)
				elseif msg == "slowrepeat" then
					play_sound(pos, pos_hash, "digistuff_piezo_slow_repeat", true)
				elseif msg == "stop" then
					stop_sounds(pos_hash)
				end
			end
		}
	}
})

local crystal = "quartz:quartz_crystal_piece"

if not minetest.get_modpath("quartz") then
	crystal = "default:mese_crystal_fragment"
end

minetest.register_craft({
	output = "digistuff:piezo",
	recipe = {
		{crystal,"basic_materials:steel_strip"},
		{"digilines:wire_std_00000000","mesecons_luacontroller:luacontroller0000"},
	},
})

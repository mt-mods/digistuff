if not minetest.get_modpath("mesecons_noteblock") then
	minetest.log("warning","mesecons_noteblock is not installed - digilines noteblock will not be available!")
	return
end

local validnbsounds = dofile(minetest.get_modpath(minetest.get_current_modname())..DIR_DELIM.."nbsounds.lua")

function digistuff.register_nb_sound(name,filename)
	validnbsounds[name] = filename
end

minetest.register_node("digistuff:noteblock", {
	description = "Digilines Noteblock",
	groups = {cracky=3},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec","field[channel;Channel;${channel}")
	end,
	on_destruct = function(pos)
		local pos_hash = minetest.hash_node_position(pos)
		if digistuff.sounds_playing[pos_hash] then
			minetest.sound_stop(digistuff.sounds_playing[pos_hash])
			digistuff.sounds_playing[pos_hash] = nil
		end
	end,
	tiles = {
		"mesecons_noteblock.png"
		},
	_digistuff_channelcopier_fieldname = "channel",
	on_receive_fields = function(pos, formname, fields, sender)
		local name = sender:get_player_name()
		if minetest.is_protected(pos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
			minetest.record_protection_violation(pos,name)
			return
		end
		local meta = minetest.get_meta(pos)
		if fields.channel then meta:set_string("channel",fields.channel) end
	end,
	digiline =
	{
		receptor = {},
		effector = {
			action = function(pos,node,channel,msg)
					local meta = minetest.get_meta(pos)
					local setchan = meta:get_string("channel")
					if channel ~= setchan then return end
					if msg == "get_sounds" then
						local soundnames = {}
						for i in pairs(validnbsounds) do
							table.insert(soundnames,i)
						end
						digilines.receptor_send(pos, digilines.rules.default, channel, soundnames)
						return
					end
					if type(msg) == "string" then
						local sound = validnbsounds[msg]
						if sound then minetest.sound_play(sound,{pos=pos}) end
					elseif type(msg) == "table" then
						if type(msg.sound) ~= "string" then return end
						for _,i in ipairs({"pitch","speed","volume","gain",}) do
							if type(msg[i]) == "string" then
								msg[i] = tonumber(msg[i])
							end
						end
						local sound = validnbsounds[msg.sound]
						if not msg.volume then msg.volume = msg.gain end
						local volume = 1
						if type(msg.volume) == "number" then
							volume = math.max(0,math.min(1,msg.volume))
						end
						if not msg.pitch then msg.pitch = msg.speed end
						local pitch = 1
						if type(msg.pitch) == "number" then
							pitch = math.max(0.05,math.min(10,msg.pitch))
						end
						if sound then
							if type(msg.cut) == "number" and msg.cut >= 0 then
								msg.cut = math.min(msg.cut,10)
								local handle = minetest.sound_play({name = sound,gain = volume,},{pos = pos,pitch = pitch,},false)
								minetest.after(msg.cut,minetest.sound_stop,handle)
							elseif type(msg.fadestep) == "number" and type(msg.fadegain) == "number" and msg.fadegain >= 0 and type(msg.fadestart) == "number" and msg.fadestart >= 0 then
								local handle = minetest.sound_play({name = sound,gain = volume,},{pos = pos,pitch = pitch,},false)
								minetest.after(msg.fadestart,minetest.sound_fade,handle,msg.fadestep,msg.fadegain)
							else
								minetest.sound_play({name = sound,gain = volume,},{pos = pos,pitch = pitch,},true)
							end
						end
					end
				end
		},
	},
})

minetest.register_craft({
	output = "digistuff:noteblock",
	recipe = {
		{"mesecons_noteblock:noteblock"},
		{"mesecons_luacontroller:luacontroller0000"},
		{"digilines:wire_std_00000000"},
	},
})

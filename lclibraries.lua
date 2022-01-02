if type(mesecon.luacontroller_libraries) == "table" then
	local tslib = {
		getColorEscapeSequence = function(color)
			return(string.char(0x1b).."(c@"..color..")")
		end,
		colorize = function(color,message)
			return(string.char(0x1b).."(c@"..color..")"..message..string.char(0x1b).."(c@#FFFFFF)")
		end,
		explode_textlist_event = function(event)
			local ret = {type = "INV"}
			if string.sub(event,1,3) == "CHG" then
				local index = tonumber(string.sub(event,5,-1))
				if index then
					ret.type = "CHG"
					ret.index = index
				end
			elseif string.sub(event,1,3) == "DCL" then
				local index = tonumber(string.sub(event,5,-1))
				if index then
					ret.type = "DCL"
					ret.index = index
				end
			end
			return ret
		end,
		_mt = {
			setChannel = function(self,channel)
				self._channel = channel
			end,
			getChannel = function(self)
				return(self._channel)
			end,
			draw = function(self)
				digiline_send(self._channel,self._commands)
			end,
			clear = function(self)
				self._commands = {{command="clear"}}
			end,
			setLock = function(self,lock)
				if lock then
					table.insert(self._commands,{command="lock"})
				else
					table.insert(self._commands,{command="unlock"})
				end
			end,
			addLabel = function(self,x,y,label,vertical)
				assert((type(x))=="number","Invalid X position")
				assert((type(y))=="number","Invalid Y position")
				if type(label) ~= "string" then
					label = tostring(label)
				end
				local cmd = {
					command = "addlabel",
					X = x,
					Y = y,
					label = label,
				}
				if vertical then cmd.command = "addvertlabel" end
				table.insert(self._commands,cmd)
			end,
			addImage = function(self,x,y,w,h,tex)
				assert((type(x))=="number","Invalid X position")
				assert((type(y))=="number","Invalid Y position")
				assert((type(w))=="number","Invalid width")
				assert((type(h))=="number","Invalid height")
				if type(tex) ~= "string" then
					tex = tostring(tex)
				end
				local cmd = {
					command = "addimage",
					X = x,
					Y = y,
					W = w,
					H = h,
					texture_name = tex,
				}
				table.insert(self._commands,cmd)
			end,
			addButton = function(self,x,y,w,h,name,label,exit)
				assert((type(x))=="number","Invalid X position")
				assert((type(y))=="number","Invalid Y position")
				assert((type(w))=="number","Invalid width")
				assert((type(h))=="number","Invalid height")
				if type(name) ~= "string" then
					name = tostring(name)
				end
				if type(label) ~= "string" then
					label = tostring(label)
				end
				local cmd = {
					command = "addbutton",
					X = x,
					Y = y,
					W = w,
					H = h,
					name = name,
					label = label,
				}
				if exit then cmd.command = "addbutton_exit" end
				table.insert(self._commands,cmd)
			end,
			addImageButton = function(self,x,y,w,h,name,label,tex,exit)
				assert((type(x))=="number","Invalid X position")
				assert((type(y))=="number","Invalid Y position")
				assert((type(w))=="number","Invalid width")
				assert((type(h))=="number","Invalid height")
				if type(name) ~= "string" then
					name = tostring(name)
				end
				if type(label) ~= "string" then
					label = tostring(label)
				end
				if type(tex) ~= "string" then
					tex = tostring(tex)
				end
				local cmd = {
					command = "addimage_button",
					X = x,
					Y = y,
					W = w,
					H = h,
					name = name,
					label = label,
					image = tex,
				}
				if exit then cmd.command = "addimage_button_exit" end
				table.insert(self._commands,cmd)
			end,
			addField = function(self,x,y,w,h,name,label,default,password)
				assert((type(x))=="number","Invalid X position")
				assert((type(y))=="number","Invalid Y position")
				assert((type(w))=="number","Invalid width")
				assert((type(h))=="number","Invalid height")
				if type(name) ~= "string" then
					name = tostring(name)
				end
				if type(label) ~= "string" then
					label = tostring(label)
				end
				if type(default) ~= "string" then
					default = tostring(default)
				end
				local cmd = {
					command = "addfield",
					X = x,
					Y = y,
					W = w,
					H = h,
					name = name,
					label = label,
					default = default,
				}
				if password then cmd.command = "addpwdfield" end
				table.insert(self._commands,cmd)
			end,
			addTextArea = function(self,x,y,w,h,name,label,default)
				assert((type(x))=="number","Invalid X position")
				assert((type(y))=="number","Invalid Y position")
				assert((type(w))=="number","Invalid width")
				assert((type(h))=="number","Invalid height")
				if type(name) ~= "string" then
					name = tostring(name)
				end
				if type(label) ~= "string" then
					label = tostring(label)
				end
				if type(default) ~= "string" then
					default = tostring(default)
				end
				local cmd = {
					command = "addtextarea",
					X = x,
					Y = y,
					W = w,
					H = h,
					name = name,
					label = label,
					default = default,
				}
				table.insert(self._commands,cmd)
			end,
			addDropdown = function(self,x,y,w,h,name,choices,selected)
				assert((type(x))=="number","Invalid X position")
				assert((type(y))=="number","Invalid Y position")
				assert((type(w))=="number","Invalid width")
				assert((type(h))=="number","Invalid height")
				if not selected then selected = 1 end
				assert((type(selected))=="number","Invalid selection index")
				if type(name) ~= "string" then
					name = tostring(name)
				end
				assert((type(choices) == "table" and #choices >= 1),"Invalid choices list")
				local cmd = {
					command = "adddropdown",
					X = x,
					Y = y,
					W = w,
					H = h,
					name = name,
					choices = choices,
					selected_id = selected,
				}
				table.insert(self._commands,cmd)
			end,
			addTextlist = function(self,x,y,w,h,name,choices,selected,transparent)
				assert((type(x))=="number","Invalid X position")
				assert((type(y))=="number","Invalid Y position")
				assert((type(w))=="number","Invalid width")
				assert((type(h))=="number","Invalid height")
				if not selected then selected = 1 end
				assert((type(selected))=="number","Invalid selection index")
				if type(name) ~= "string" then
					name = tostring(name)
				end
				assert((type(transparent)) == "boolean","Invalid transparent flag")
				assert((type(choices) == "table" and #choices >= 1),"Invalid choices list")
				local cmd = {
					command = "addtextlist",
					X = x,
					Y = y,
					W = w,
					H = h,
					name = name,
					listelements = choices,
					selected_id = selected,
					transparent = transparent,
				}
				table.insert(self._commands,cmd)
			end,
		},
		new = function(self,channel)
			local ret = {}
			for k,v in pairs(self._mt) do
				ret[k] = v
			end
			ret._channel = channel
			ret._commands = {{command="clear"}}
			return ret
		end,
	}
	mesecon.luacontroller_libraries.TSLib = tslib
	
	local libexpander = {
		pre_hook = function()
			if event.type == "program" then
				mem.__libexpander_registered = {}
			end
			if event.type == "digiline" then
				local oldevent = event
				for k,v in pairs(mem.__libexpander_registered) do
					if k == oldevent.channel then
						if oldevent.msg.a ~= v.pinastate and v.pina then
							mem.__libexpander_registered[k].pinastate = oldevent.msg.a
							event = {
								type = v.pinastate and "on" or "off",
								pin = {
									name = string.upper(v.pina),
									channel = oldevent.channel,
									virtual = true,
								},
							}
						end
						if oldevent.msg.b ~= v.pinbstate and v.pinb then
							mem.__libexpander_registered[k].pinbstate = oldevent.msg.b
							event = {
								type = v.pinbstate and "on" or "off",
								pin = {
									name = string.upper(v.pinb),
									channel = oldevent.channel,
									virtual = true,
								},
							}
						end
						if oldevent.msg.c ~= v.pincstate and v.pinc then
							mem.__libexpander_registered[k].pincstate = oldevent.msg.c
							event = {
								type = v.pincstate and "on" or "off",
								pin = {
									name = string.upper(v.pinc),
									channel = oldevent.channel,
									virtual = true,
								},
							}
						end
						if oldevent.msg.d ~= v.pindstate and v.pind then
							mem.__libexpander_registered[k].pindstate = oldevent.msg.d
							event = {
								type = v.pindstate and "on" or "off",
								pin = {
									name = string.upper(v.pind),
									channel = oldevent.channel,
									virtual = true,
								},
							}
						end
					end
				end
			end
			for _,v in pairs(mem.__libexpander_registered) do
				if v.pina then
					pin[v.pina] = v.pinastate
					port[v.pina] = v.portastate
				end
				if v.pinb then
					pin[v.pinb] = v.pinbstate
					port[v.pinb] = v.portbstate
				end
				if v.pinc then
					pin[v.pinc] = v.pincstate
					port[v.pinc] = v.portcstate
				end
				if v.pind then
					pin[v.pind] = v.pindstate
					port[v.pind] = v.portdstate
				end
			end
		end,
		post_hook = function()
			for k,v in pairs(mem.__libexpander_registered) do
				local changed = false
				if v.pina and (v.portastate ~= port[v.pina]) then
					changed = true
					v.portastate = port[v.pina]
				end
				if v.pinb and (v.portbstate ~= port[v.pinb]) then
					changed = true
					v.portbstate = port[v.pinb]
				end
				if v.pinc and (v.portcstate ~= port[v.pinc]) then
					changed = true
					v.portcstate = port[v.pinc]
				end
				if v.pind and (v.portdstate ~= port[v.pind]) then
					changed = true
					v.portdstate = port[v.pind]
				end
				if changed then
					digiline_send(k,{a = v.portastate,b = v.portbstate,c = v.portcstate,d = v.portdstate})
				end
			end
		end,
		new = function(channel,pina,pinb,pinc,pind)
			assert(type(channel) == "string","Invalid channel")
			local def = {pinastate = false,pinbstate = false,pincstate = false,pindstate = false,portastate = false,portbstate = false,portcstate = false,portdstate = false,}
			if type(pina) == "string" then def.pina = pina end
			if type(pinb) == "string" then def.pinb = pinb end
			if type(pinc) == "string" then def.pinc = pinc end
			if type(pind) == "string" then def.pind = pind end
			mem.__libexpander_registered[channel] = def
			digiline_send(channel,"GET")
		end,
		delete = function(channel)
			mem.__libexpander_registered[channel] = nil
		end,
	}
	mesecon.luacontroller_libraries.libexpander = libexpander
	
	local libdetector = {
		pre_hook = function()
			if event.type == "program" then
				mem.__libdetector_registered = {}
			end
			if event.type == "digiline" then
				local channel = event.channel
				if mem.__libdetector_registered[channel] then
					if not mem.__libdetector_registered[channel].active then
						mem.__libdetector_registered[channel].active = true
						if not port[string.lower(mem.__libdetector_registered[channel].virtualpin)] then
							event = {
								type = "on",
								pin = {
									name = string.upper(mem.__libdetector_registered[channel].virtualpin),
									channel = channel,
									virtual = true,
								},
							}
						end
					end
					interrupt(mem.__libdetector_registered[channel].timeout,"__libdetector"..channel)
				end
			end
			if event.type == "interrupt" and string.sub(event.iid,1,13) == "__libdetector" then
				local channel = string.sub(event.iid,14,-1)
				if mem.__libdetector_registered[channel] then
					mem.__libdetector_registered[channel].active = false
					if not port[string.lower(mem.__libdetector_registered[channel].virtualpin)] then
						event = {
							type = "off",
							pin = {
								name = string.upper(mem.__libdetector_registered[channel].virtualpin),
								channel = channel,
								virtual = true,
							},
						}
					end
				end
			end
			for k,v in pairs(mem.__libdetector_registered) do
				pin[string.lower(v.virtualpin)] = v.active or port[string.lower(v.virtualpin)]
			end
		end,
		new = function(channel,virtualpin,timeout)
			if not tonumber(timeout) then timeout = 1.5 end
			timeout = math.max(0.5,timeout)
			assert(type(channel) == "string","channel must be a string")
			assert(type(virtualpin) == "string","virtualpin must be a string")
			mem.__libdetector_registered[channel] = {
				virtualpin = virtualpin,
				timeout = timeout,
				active = false,
			}
		end,
		delete = function(channel)
			if not mem.__libdetector_registered[channel] then return false end
			mem.__libdetector_registered[channel] = nil
			return true
		end,
	}
	mesecon.luacontroller_libraries.libdetector = libdetector
end

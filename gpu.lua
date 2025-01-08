local font = dofile(minetest.get_modpath("digistuff") .. "/gpu-font.lua")
local MAX_BUFFERS = 8

local function explodebits(input, count)
	local output = {}
	count = count or 8
	for i = 0, count - 1 do
		output[i] = input % (2^(i + 1)) >= 2^i
	end
	return output
end

local function implodebits(input, count)
	local output = 0
	count = count or 8
	for i = 0, count - 1 do
		output = output + (input[i] and 2^i or 0)
	end
	return output
end

local packtable = {}
local unpacktable = {}
for i = 0, 25 do
	packtable[i] = string.char(i + 65)
	packtable[i + 26] = string.char(i + 97)
	unpacktable[string.char(i + 65)] = i
	unpacktable[string.char(i + 97)] = i + 26
end
for i = 0, 9 do
	packtable[i + 52] = tostring(i)
	unpacktable[tostring(i)] = i + 52
end
packtable[62] = "+"
packtable[63] = "/"
unpacktable["+"] = 62
unpacktable["/"] = 63

local function packpixel(pixel)
	pixel = tonumber(pixel, 16)
	if not pixel then
		return "AAAA"
	end

	local bits = explodebits(pixel, 24)
	local block1 = {}
	local block2 = {}
	local block3 = {}
	local block4 = {}
	for i = 0, 5 do
		block1[i] = bits[i]
		block2[i] = bits[i + 6]
		block3[i] = bits[i + 12]
		block4[i] = bits[i + 18]
	end
	local char1 = packtable[implodebits(block1, 6)] or "A"
	local char2 = packtable[implodebits(block2, 6)] or "A"
	local char3 = packtable[implodebits(block3, 6)] or "A"
	local char4 = packtable[implodebits(block4, 6)] or "A"
	return char1 .. char2 .. char3 .. char4
end

local function unpackpixel(pack)
	local block1 = unpacktable[pack:sub(1, 1)] or 0
	local block2 = unpacktable[pack:sub(2, 2)] or 0
	local block3 = unpacktable[pack:sub(3, 3)] or 0
	local block4 = unpacktable[pack:sub(4, 4)] or 0
	local out = block1 + (2^6 * block2) + (2^12 * block3) + (2^18 * block4)
	return string.format("%06X", out)
end

local function rgbtohsv(r, g, b)
	r = r / 255
	g = g / 255
	b = b / 255
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local delta = max - min
	local hue = 0
	if delta > 0 then
		if max == r then
			hue = (g - b) / delta
			hue = (hue % 6) * 60
		elseif max == g then
			hue = (b - r) / delta
			hue = 60 * (hue + 2)
		elseif max == b then
			hue = (r - g) / delta
			hue = 60 * (hue + 4)
		end
		hue = hue / 360
	end
	local sat = 0
	if max > 0 then
		sat = delta / max
	end
	return math.floor(hue * 255), math.floor(sat * 255), math.floor(max * 255)
end

local function hsvtorgb(h, s, v)
	h = h / 255 * 360
	s = s / 255
	v = v / 255
	local c = s * v
	local x = (h / 60) % 2
	x = 1 - math.abs(x - 1)
	x = x * c
	local m = v - c
	local r = 0
	local g = 0
	local b = 0
	if h < 60 then
		r = c
		g = x
	elseif h < 120 then
		r = x
		g = c
	elseif h < 180 then
		g = c
		b = x
	elseif h < 240 then
		g = x
		b = c
	elseif h < 300 then
		r = x
		b = c
	else
		r = c
		b = x
	end
	r = r + m
	g = g + m
	b = b + m
	return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

local function bitwiseblend(srcr, dstr, srcg, dstg, srcb, dstb, mode)
	local srbits = explodebits(srcr)
	local sgbits = explodebits(srcg)
	local sbbits = explodebits(srcb)
	local drbits = explodebits(dstr)
	local dgbits = explodebits(dstg)
	local dbbits = explodebits(dstb)
	for i = 0, 7 do
		if mode == "and" then
			drbits[i] = srbits[i] and drbits[i]
			dgbits[i] = sgbits[i] and dgbits[i]
			dbbits[i] = sbbits[i] and dbbits[i]
		elseif mode == "or" then
			drbits[i] = srbits[i] or drbits[i]
			dgbits[i] = sgbits[i] or dgbits[i]
			dbbits[i] = sbbits[i] or dbbits[i]
		elseif mode == "xor" then
			drbits[i] = srbits[i] ~= drbits[i]
			dgbits[i] = sgbits[i] ~= dgbits[i]
			dbbits[i] = sbbits[i] ~= dbbits[i]
		elseif mode == "xnor" then
			drbits[i] = srbits[i] == drbits[i]
			dgbits[i] = sgbits[i] == dgbits[i]
			dbbits[i] = sbbits[i] == dbbits[i]
		elseif mode == "not" then
			drbits[i] = not srbits[i]
			dgbits[i] = not sgbits[i]
			dbbits[i] = not sbbits[i]
		elseif mode == "nand" then
			drbits[i] = not (srbits[i] and drbits[i])
			dgbits[i] = not (sgbits[i] and dgbits[i])
			dbbits[i] = not (sbbits[i] and dbbits[i])
		elseif mode == "nor" then
			drbits[i] = not (srbits[i] or drbits[i])
			dgbits[i] = not (sgbits[i] or dgbits[i])
			dbbits[i] = not (sbbits[i] or dbbits[i])
		end
	end
	return string.format("%02X%02X%02X",
		implodebits(drbits), implodebits(dgbits), implodebits(dbbits))
end

local function blend(src, dst, mode, transparent)
	local srcr = tonumber(string.sub(src, 1, 2), 16)
	local srcg = tonumber(string.sub(src, 3, 4), 16)
	local srcb = tonumber(string.sub(src, 5, 6), 16)
	local dstr = tonumber(string.sub(dst, 1, 2), 16)
	local dstg = tonumber(string.sub(dst, 3, 4), 16)
	local dstb = tonumber(string.sub(dst, 5, 6), 16)
	local op = "normal"
	if type(mode) == "string" then
		op = string.lower(mode)
	end
	if op == "normal" then
		return src

	elseif op == "nop" then
		return dst

	elseif op == "overlay" then
		return string.upper(src) == string.upper(transparent) and dst or src

	elseif op == "add" then
		local r = math.min(255, srcr + dstr)
		local g = math.min(255, srcg + dstg)
		local b = math.min(255, srcb + dstb)
		return string.format("%02X%02X%02X", r, g, b)

	elseif op == "sub" then
		local r = math.max(0, dstr - srcr)
		local g = math.max(0, dstg - srcg)
		local b = math.max(0, dstb - srcb)
		return string.format("%02X%02X%02X", r, g, b)

	elseif op == "isub" then
		local r = math.max(0, srcr - dstr)
		local g = math.max(0, srcg - dstg)
		local b = math.max(0, srcb - dstb)
		return string.format("%02X%02X%02X", r, g, b)

	elseif op == "average" then
		local r = math.min(255, (srcr + dstr) / 2)
		local g = math.min(255, (srcg + dstg) / 2)
		local b = math.min(255, (srcb + dstb) / 2)
		return string.format("%02X%02X%02X", r, g, b)

	elseif op == "and"
		or op == "or"
		or op == "xor"
		or op == "xnor"
		or op == "not"
		or op == "nand"
		or op == "nor"
	then
		return bitwiseblend(srcr, dstr, srcg, dstg, srcb, dstb, op)

	elseif op == "tohsv"
		or op == "rgbtohsv"
	then
		return string.format("%02X%02X%02X", rgbtohsv(srcr, srcg, srcb))

	elseif op == "torgb"
		or op == "hsvtorgb"
	then
		return string.format("%02X%02X%02X",hsvtorgb(srcr, srcg, srcb))
	end

	return src
end

local function validate_area(buffer, x1, y1, x2, y2)
	if not (buffer and buffer.xsize and buffer.ysize)
		or type(x1) ~= "number"
		or type(x2) ~= "number"
		or type(y1) ~= "number"
		or type(y2) ~= "number"
	then
		return
	end

	x1 = math.max(1, math.min(buffer.xsize, math.floor(x1)))
	x2 = math.max(1, math.min(buffer.xsize, math.floor(x2)))
	y1 = math.max(1, math.min(buffer.ysize, math.floor(y1)))
	y2 = math.max(1, math.min(buffer.ysize, math.floor(y2)))
	if x1 > x2 then
		x1, x2 = x2, x1
	end
	if y1 > y2 then
		y1, y2 = y2, y1
	end
	return x1, y1, x2, y2
end

local function validate_size(size)
	if type(size) ~= "number" then
		return 1
	end
	return math.max(1, math.min(64, math.floor(math.abs(size))))
end

local function validate_color(fillcolor, fallback)
	fallback = fallback or "000000"
	if type(fillcolor) ~= "string"
		or string.len(fillcolor) > 7
		or string.len(fillcolor) < 6
	then
		fillcolor = fallback
	end
	if string.sub(fillcolor, 1, 1) == "#" then
		fillcolor = string.sub(fillcolor, 2, 7)
	end
	if not tonumber(fillcolor, 16) then
		fillcolor = fallback
	end
	return fillcolor
end

local function validate_buffer_address(bufnum)
	if type(bufnum) ~= "number" then
		return
	end

	bufnum = math.floor(math.abs(bufnum))
	return MAX_BUFFERS > bufnum and bufnum or nil
end

local function read_buffer(meta, bufnum)
	local buffer = minetest.deserialize(meta:get_string("buffer" .. bufnum))
	return type(buffer) == "table" and buffer or nil
end

local function write_buffer(meta, bufnum, buffer)
	meta:set_string("buffer" .. bufnum, minetest.serialize(buffer))
end

local function runcommand(pos, meta, command)
	if type(command) ~= "table"
		or type(command.buffer) ~= "number"
	then
		return
	end

	local bufnum = validate_buffer_address(command.buffer)
	if not bufnum then
		return
	end

	local buffer
	if command.command ~= "createbuffer" then
		buffer = read_buffer(meta, bufnum)
		if not buffer then
			return
		end
	end

	local xsize, ysize, x1, x2, y1, y2
	local color, fillcolor, edgecolor
	if command.command == "createbuffer" then
		xsize = validate_size(command.xsize)
		ysize = validate_size(command.ysize)
		fillcolor = validate_color(command.fill)
		buffer = { xsize = xsize, ysize = ysize }
		for y = 1, ysize do
			buffer[y] = {}
			for x = 1, xsize do
				buffer[y][x] = fillcolor
			end
		end
		write_buffer(meta, bufnum, buffer)
	elseif command.command == "send" then
		if type(command.channel) ~= "string" then
			return
		end

		digilines.receptor_send(pos, digilines.rules.default,
			command.channel, buffer)

	elseif command.command == "sendregion" then
		if type(command.channel) ~= "string" then
			return
		end

		x1, y1, x2, y2 = validate_area(buffer,
			command.x1, command.y1, command.x2, command.y2)

		if not x1 then
			return
		end

		local tempbuf, dstx, dsty = {}
		for y = y1, y2 do
			dsty = y - y1 + 1
			tempbuf[dsty] = {}
			for x = x1, x2 do
				dstx = x - x1 + 1
				tempbuf[dsty][dstx] = buffer[y][x]
			end
		end
		digilines.receptor_send(pos, digilines.rules.default,
			command.channel, tempbuf)

	elseif command.command == "drawrect" then
		x1, y1, x2, y2 = validate_area(buffer,
			command.x1, command.y1, command.x2, command.y2)

		if not x1 then
			return
		end

		fillcolor = validate_color(command.fill)
		edgecolor = validate_color(command.edge, fillcolor)
		for y = y1, y2 do
			for x = x1, x2 do
				buffer[y][x] = fillcolor
			end
		end
		if fillcolor ~= edgecolor then
			for x = x1, x2 do
				buffer[y1][x] = edgecolor
				buffer[y2][x] = edgecolor
			end
			for y = y1, y2 do
				buffer[y][x1] = edgecolor
				buffer[y][x2] = edgecolor
			end
		end
		write_buffer(meta, bufnum, buffer)
	elseif command.command == "drawline" then
		x1, y1, x2, y2 = validate_area(buffer,
			command.x1, command.y1, command.x2, command.y2)

		if not x1 then
			return
		end

		color = validate_color(command.color)
		local p1 = vector.new(x1, y1, 0)
		local p2 = vector.new(x2, y2, 0)
		local length = 1 + vector.distance(p1, p2)
		local dir = vector.direction(p1, p2)
		local point
		-- not the most eficient process for horizontal, vertical
		-- or 45 degree lines
		for i = 0, length, 0.3 do
			point = vector.add(p1, vector.multiply(dir, i))
			point = vector.floor(point)
			if command.antialias then
				buffer[point.y][point.x] = blend(
					buffer[point.y][point.x], color, "average")
			else
				buffer[point.y][point.x] = color
			end
		end
		write_buffer(meta, bufnum, buffer)
	elseif command.command == "drawpoint" then
		x1, y1 = validate_area(buffer, command.x, command.y, command.x, command.y)
		if not x1 then
			return
		end

		buffer[y1][x1] = validate_color(command.color)
		write_buffer(meta, bufnum, buffer)
	elseif command.command == "copy" then
		if type(command.xsize) ~= "number"
			or type(command.ysize) ~= "number"
		then
			return
		end

		x1, y1 = validate_area(buffer,
			command.srcx, command.srcy, command.srcx, command.srcy)

		x2, y2 = validate_area(buffer,
			command.dstx, command.dsty, command.dstx, command.dsty)

		if not (x1 and x2) then
			return
		end

		local src = validate_buffer_address(command.src)
		local dst = validate_buffer_address(command.dst)
		if not (src and dst) then
			return
		end

		local sourcebuffer = read_buffer(meta, src)
		local destbuffer = read_buffer(meta, dst)
		if not (sourcebuffer and destbuffer) then
			return
		end

		-- clamp size to source and offset
		xsize = math.min(sourcebuffer.xsize - x1 + 1, validate_size(command.xsize))
		ysize = math.min(sourcebuffer.ysize - y1 + 1, validate_size(command.ysize))
		-- clamp size to destination and offset
		xsize = math.min(destbuffer.xsize - x2 + 1, xsize)
		ysize = math.min(destbuffer.ysize - y2 + 1, ysize)

		local transparent = validate_color(command.transparent)
		local px1, px2
		for y = 0, ysize - 1 do
			for x = 0, xsize - 1 do
				px1 = sourcebuffer[y1 + y][x1 + x]
				px2 = destbuffer[y2 + y][x2 + x]
				destbuffer[y2 + y][x2 + x] = blend(
					px1, px2, command.mode, transparent)
			end
		end
		write_buffer(meta, dst, destbuffer)
	elseif command.command == "load" then
		x1, y1 = validate_area(buffer, command.x, command.y, command.x, command.y)
		if not x1
			or type(command.data) ~= "table"
			or type(command.data[1]) ~= "table"
			or #command.data[1] < 1
		then
			return
		end

		ysize = math.min(buffer.ysize - y1 + 1, validate_size(#command.data))
		xsize = math.min(buffer.xsize - x1 + 1, validate_size(#command.data[1]))
		for y = 1, ysize do
			if type(command.data[y]) == "table" then
				for x = 1, xsize do
					-- slightly different behaviour from before refactor:
					-- illegal values are now set to '000000' instead of being skipped
					buffer[y1 + y - 1][x1 + x - 1] = validate_color(
						command.data[y][x])
				end
			end
		end
		write_buffer(meta, bufnum, buffer)
	elseif command.command == "text" then
		x1, y1 = validate_area(buffer, command.x, command.y, command.x, command.y)
		if not x1
			or x1 > buffer.xsize
			or y1 > buffer.ysize
			or type(command.text) ~= "string"
			or string.len(command.text) < 1
		then
			return
		end

		command.text = string.sub(command.text, 1, 16)
		color = validate_color(command.color, "ff6600")
		local char, px
		for i = 1, string.len(command.text) do
			char = font[string.byte(string.sub(command.text, i, i))]
			for chary = 1, 12 do
				for charx = 1, 5 do
					x2 = x1 + (i * 6 - 6)
					if char[chary][charx] and y1 + chary - 1 <= buffer.ysize
						and x2 + charx - 1 <= buffer.xsize
					then
						px = buffer[y1 + chary - 1][x2 + charx - 1]
						buffer[y1 + chary - 1][x2 + charx - 1] = blend(
							color, px, command.mode, "")
					end
				end
			end
		end
		write_buffer(meta, bufnum, buffer)
	elseif command.command == "sendpacked" then
		if type(command.channel) ~= "string" then
			return
		end
		local packedtable = {}
		for y = 1, buffer.ysize do
			for x = 1, buffer.xsize do
				table.insert(packedtable, packpixel(buffer[y][x]))
			end
		end
		local packeddata = table.concat(packedtable, "")
		digilines.receptor_send(pos, digilines.rules.default,
			command.channel, packeddata)
	elseif command.command == "loadpacked" then
		x1, y1 = validate_area(buffer, command.x, command.y, command.x, command.y)
		if not x1
			or type(command.data) ~= "string"
		then
			return
		end

		-- clamp size to buffer size
		xsize = math.min(buffer.xsize - x1 + 1, validate_size(command.xsize))
		ysize = math.min(buffer.ysize - y1 + 1, validate_size(command.ysize))
		local packidx, packeddata
		for y = 0, ysize - 1 do
			y2 = y1 + y
			for x = 0, xsize - 1 do
				x2 = x1 + x
				packidx = (y * xsize + x) * 4 + 1
				packeddata = string.sub(command.data, packidx, packidx + 3)
				buffer[y2][x2] = unpackpixel(packeddata)
			end
		end
		write_buffer(meta, bufnum, buffer)
	end
end

minetest.register_node("digistuff:gpu", {
	description = "Digilines 2D Graphics Processor",
	groups = { cracky = 3 },
	is_ground_content = false,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "field[channel;Channel;${channel}")
	end,
	tiles = {
		"digistuff_gpu_top.png",
		"jeija_microcontroller_bottom.png",
		"jeija_microcontroller_sides.png",
		"jeija_microcontroller_sides.png",
		"jeija_microcontroller_sides.png",
		"jeija_microcontroller_sides.png"
	},
	inventory_image = "digistuff_gpu_top.png",
	drawtype = "nodebox",
	selection_box = {
		--From luacontroller
		type = "fixed",
		fixed = { -8/16, -8/16, -8/16, 8/16, -5/16, 8/16 },
	},
	_digistuff_channelcopier_fieldname = "channel",
	node_box = {
		--From Luacontroller
		type = "fixed",
		fixed = {
			{ -8/16, -8/16, -8/16, 8/16, -7/16, 8/16 }, -- Bottom slab
			{ -5/16, -7/16, -5/16, 5/16, -6/16, 5/16 }, -- Circuit board
			{ -3/16, -6/16, -3/16, 3/16, -5/16, 3/16 }, -- IC
		}
	},
	paramtype = "light",
	sunlight_propagates = true,
	on_receive_fields = function(pos, formname, fields, sender)
		-- Below link to lua_api.md says: not to check formname
		-- https://github.com/minetest/minetest/blob/2efd0996e61fe82a4922224fa8c039116281d345/doc/lua_api.md?plain=1#L9674
		if not fields.channel then
			return
		end

		local name = sender:get_player_name()
		if minetest.is_protected(pos, name)
			and not minetest.check_player_privs(name, { protection_bypass = true })
		then
			minetest.record_protection_violation(pos, name)
			return
		end

		local meta = minetest.get_meta(pos)
		meta:set_string("channel", fields.channel)
	end,
	digiline = {
		receptor = {},
		effector = {
			action = function(pos, node, channel, msg)
				local meta = minetest.get_meta(pos)
				if meta:get_string("channel") ~= channel
					or type(msg) ~= "table"
				then
					return
				end

				if type(msg[1]) == "table" then
					for i = 1, 32 do
						if type(msg[i]) == "table" then
							runcommand(pos, meta, msg[i])
						end
					end
				else
					runcommand(pos, meta, msg)
				end
			end
		},
	},
})

minetest.register_craft({
	output = "digistuff:gpu",
	recipe = {
		{ "", "default:steel_ingot", "" },
		{
			"digilines:wire_std_00000000",
			"mesecons_luacontroller:luacontroller0000",
			"digilines:wire_std_00000000"
		},
		{ "dye:red", "dye:green", "dye:blue" }
	}
})

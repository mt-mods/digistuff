local font = dofile(minetest.get_modpath("digistuff") .. "/gpu-font.lua")
local MAX_BUFFERS = 8
local MAX_SIZE = 64
local MAX_COMMANDS = 32

-- yes i know it may feel like way too many instructions
-- but consider:
--  - if a shader is running over a MAX_SIZE*MAX_SIZE image, it will only have 100 instructions to work with
--  - Shaders cannot do the really expensive instructions/calls to C that mesecons luacontroller can, like string concatination (still a sandbox weakness!) or string.rep("a", 64000), thats a very little amount instructions for a lot more lag
--  (shaders can mostly do just math, not string manipulation, and not even much table manipulation)
local MAX_SHADER_INSTRUCTIONS = 200 * (MAX_SIZE * MAX_SIZE)
local MAX_SHADER_CODE_LENGTH = 1000

local function explodebits(input, count)
	local output = {}
	count = count or 8
	for i = 0, count - 1 do
		output[i] = input % (2 ^ (i + 1)) >= 2 ^ i
	end
	return output
end

local function implodebits(input, count)
	local output = 0
	count = count or 8
	for i = 0, count - 1 do
		output = output + (input[i] and 2 ^ i or 0)
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
	if not pixel then return "AAAA" end

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
	local out = block1 + (2 ^ 6 * block2) + (2 ^ 12 * block3) + (2 ^ 18 * block4)
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
	if max > 0 then sat = delta / max end
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
	return string.format("%02X%02X%02X", implodebits(drbits), implodebits(dgbits), implodebits(dbbits))
end

local bit_band, bit_rshift = bit.band, bit.rshift -- works in PUC lua too
local function unpack_color(color)
	local current_color_number = tonumber(color, 16) -- this is a "stich" on luaJIT, so tonumber(x, 16) calls should be minimized, ideally replaced, ideally this all should not be needed and the color would just be a number
	return bit_band(bit_rshift(current_color_number, 16), 0xff),
		bit_band(bit_rshift(current_color_number, 8), 0xff),
		bit_band(current_color_number, 0xff)
end

-- To avoid doing tonumber(x, 16) which is slow under luaJIT (not like its slower than PUC lua, but that its not as fast as it could be)
-- Only use this function when you have to get a color multiple times from the same pixel, from the same buffer
local function unpack_color_with_cache(cache, buffer, x, y)
	local current_color_number = cache[y][x]
	if current_color_number == nil then
		cache[y][x] = tonumber(buffer[y][x], 16)
		current_color_number = cache[y][x]
	end
	return bit_band(bit_rshift(current_color_number, 16), 0xff),
		bit_band(bit_rshift(current_color_number, 8), 0xff),
		bit_band(current_color_number, 0xff)
end

local function blend(src, dst, mode, transparent)
	local srcr, srcg, srcb = unpack_color(src)
	local dstr, dstg, dstb = unpack_color(dst)
	local op = "normal"
	if type(mode) == "string" then op = string.lower(mode) end
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
	elseif op == "and" or op == "or" or op == "xor" or op == "xnor" or op == "not" or op == "nand" or op == "nor" then
		return bitwiseblend(srcr, dstr, srcg, dstg, srcb, dstb, op)
	elseif op == "tohsv" or op == "rgbtohsv" then
		return string.format("%02X%02X%02X", rgbtohsv(srcr, srcg, srcb))
	elseif op == "torgb" or op == "hsvtorgb" then
		return string.format("%02X%02X%02X", hsvtorgb(srcr, srcg, srcb))
	end

	return src
end

local function validate_area(buffer, x1, y1, x2, y2, keep_order)
	if
		not (buffer and buffer.xsize and buffer.ysize)
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

	if keep_order then return x1, y1, x2, y2 end

	if x1 > x2 then
		x1, x2 = x2, x1
	end
	if y1 > y2 then
		y1, y2 = y2, y1
	end
	return x1, y1, x2, y2
end

local function validate_size(size)
	if type(size) ~= "number" then return 1 end
	return math.max(1, math.min(MAX_SIZE, math.floor(math.abs(size))))
end

local function validate_color(fillcolor, fallback)
	fallback = fallback or "000000"
	if type(fillcolor) ~= "string" or string.len(fillcolor) > 7 or string.len(fillcolor) < 6 then
		fillcolor = fallback
	end
	if string.sub(fillcolor, 1, 1) == "#" then fillcolor = string.sub(fillcolor, 2, 7) end
	if not tonumber(fillcolor, 16) then fillcolor = fallback end
	return fillcolor
end

local function validate_buffer_address(bufnum)
	if type(bufnum) ~= "number" then return end

	bufnum = math.floor(math.abs(bufnum))
	return MAX_BUFFERS > bufnum and bufnum or nil
end

local function validate_matrix(matrix, valid_sizes)
	if type(matrix) ~= "table" then return false end
	if not valid_sizes[#matrix] then return false end
	for y = 1, #matrix do
		local row = matrix[y]
		if type(row) ~= "table" then return false end
		if #row ~= #matrix then return false end
		for x = 1, #matrix do
			local num = matrix[y][x]
			if type(num) ~= "number" then return end
		end
	end
	return true
end

local function read_buffer(meta, bufnum)
	local buffer = minetest.deserialize(meta:get_string("buffer" .. bufnum))
	return type(buffer) == "table" and buffer or nil
end

local function write_buffer(meta, bufnum, buffer)
	meta:set_string("buffer" .. bufnum, minetest.serialize(buffer))
end

local function run_shader(env, buffer, new_buffer, f)
	for y = 1, buffer.ysize do
		for x = 1, buffer.xsize do
			env.x = x
			env.y = y
			env.r, env.g, env.b = unpack_color(buffer[y][x])
			local r, g, b = f()
			if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
				error(
					"You are supposed to return r,g,b where all of them are numbers, you sent: "
						.. tostring(r)
						.. ", "
						.. tostring(g)
						.. ", "
						.. tostring(b)
				)
			end
			r, g, b = -- rgb must be an integer between 0 and 255
				math.min(255, math.max(0, math.floor(r))),
				math.min(255, math.max(0, math.floor(g))),
				math.min(255, math.max(0, math.floor(b)))

			r, g, b = r == r and r or 0, g == g and g or 0, b == b and b or 0 -- rgb must not be nan

			local new_color = string.format("%02X%02X%02X", r, g, b)
			new_buffer[y][x] = new_color
		end
	end
end

-- Defining functions in functions is bad in luaJIT so im avoiding it
local hook = function()
	debug.sethook()
	error("Code ran for too many instructions.", 2)
end

local unlimited_run_shader = run_shader
run_shader = function(env, buffer, new_buffer, f)
	debug.sethook(hook, "", MAX_SHADER_INSTRUCTIONS)
	local ok, errmsg = pcall(unlimited_run_shader, env, buffer, new_buffer, f)
	debug.sethook()
	if not ok then error(errmsg) end
end

local function linear_transform(x, y, matrix)
	return (x * matrix[1][1]) + (y * matrix[1][2]), (x * matrix[2][1]) + (y * matrix[2][2])
end

-- it isn't an affine transform if you change the bottom row
local function affine_transform(x, y, matrix)
	local new_x = (x * matrix[1][1]) + (y * matrix[1][2]) + matrix[1][3]
	local new_y = (x * matrix[2][1]) + (y * matrix[2][2]) + matrix[2][3]
	local new_z = (x * matrix[3][1]) + (y * matrix[3][2]) + matrix[3][3]
	return new_x / new_z, new_y / new_z
end

-- This function was made with significant help from chatGPT
local function invert_2x2_matrix(matrix)
	local a, b, c, d = matrix[1][1], matrix[1][2], matrix[2][1], matrix[2][2]

	local det = (a * d) - (b * c)
	if det == 0 then return matrix end

	local inv_det = 1 / det
	local new_matrix = {
		{ d * inv_det, -b * inv_det },
		{ -c * inv_det, a * inv_det },
	}
	return new_matrix
end

-- This function was made with significant help from chatGPT
-- the reason i didn't make a generic invert_matrix function is because it looks a lot more complicated
local function invert_3x3_matrix(m)
	local a, b, c = m[1][1], m[1][2], m[1][3]
	local d, e, f = m[2][1], m[2][2], m[2][3]
	local g, h, i = m[3][1], m[3][2], m[3][3]

	local det = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
	if det == 0 then return m end

	local inv_det = 1 / det
	return {
		{ (e * i - f * h) * inv_det, (c * h - b * i) * inv_det, (b * f - c * e) * inv_det },
		{ (f * g - d * i) * inv_det, (a * i - c * g) * inv_det, (c * d - a * f) * inv_det },
		{ (d * h - e * g) * inv_det, (b * g - a * h) * inv_det, (a * e - b * d) * inv_det },
	}
end

-- Thanks wikipedia https://en.wikipedia.org/wiki/Bilinear_interpolation
-- i hope i implemented it correctly
-- Wikipedia says that the standard for affine transformations is bicubic interpolation but that looked too scary
local function bilinear_interpolation(buffer, cache, x, y)
	-- under luaJIT, "mixed sparse/dense tables" are Not Yet Implemented, i assume its accessing the buffer table like buffer[3.145][-2.34]

	local x1, y1 = math.floor(x), math.floor(y)
	local x2, y2 = math.ceil(x), math.ceil(y)
	if not (buffer[y2] and buffer[y1]) then return end
	if x1 <= 0 or y1 <= 0 then return end
	if x1 == x2 and y1 == y2 then return buffer[y1][y2] end

	local q11, q12, q21, q22 =
		buffer[y1][x1], --
		buffer[y2][x1],
		buffer[y1][x2],
		buffer[y2][x2]

	if not (q11 and q21 and q12 and q22) then return end

	if q11 == q12 and q11 == q21 and q11 == q22 then return q11 end

	-- i don't want tables as i fear the performance of them might be horrible
	local q11_r, q11_g, q11_b = unpack_color_with_cache(cache, buffer, x1, y1)
	local q12_r, q12_g, q12_b = unpack_color_with_cache(cache, buffer, x2, y1)
	local q21_r, q21_g, q21_b = unpack_color_with_cache(cache, buffer, x1, y2)
	local q22_r, q22_g, q22_b = unpack_color_with_cache(cache, buffer, x2, y2)

	local red, green, blue
	if x1 == x2 then
		local t = (y - y1) / (y2 - y1)
		red = q11_r + (q12_r - q11_r) * t
		green = q11_g + (q12_g - q11_g) * t
		blue = q11_b + (q12_b - q11_b) * t
	elseif y1 == y2 then
		local t = (x - x1) / (x2 - x1)
		red = q11_r + (q21_r - q11_r) * t
		green = q11_g + (q21_g - q11_g) * t
		blue = q11_b + (q21_b - q11_b) * t
	else
		local a, b, c, d = (x2 - x) / (x2 - x1), (x - x1) / (x2 - x1), (y2 - y) / (y2 - y1), (y - y1) / (y2 - y1)

		local p1, p2

		-- this is for each channel, im avoiding an ipairs loop so that hopefully its more performant

		p1 = a * q11_r + b * q21_r
		p2 = a * q12_r + b * q22_r
		red = c * p1 + d * p2

		p1 = a * q11_g + b * q21_g
		p2 = a * q12_g + b * q22_g
		green = c * p1 + d * p2

		p1 = a * q11_b + b * q21_b
		p2 = a * q12_b + b * q22_b
		blue = c * p1 + d * p2
	end

	red, green, blue =
		math.min(255, math.max(0, math.floor(red))),
		math.min(255, math.max(0, math.floor(green))),
		math.min(255, math.max(0, math.floor(blue)))

	if red ~= red or green ~= green or blue ~= blue then -- NAN somehow?
		return
	end

	return string.format("%02X%02X%02X", red, green, blue)
end

local function nearest_neighbor(buffer, cache, x, y)
	local round_x, round_y = math.round(x), math.round(y)
	if round_x <= 0 or round_y <= 0 then return end -- for JIT
	if buffer[round_y] then return buffer[round_y][round_x] end
end

local function runcommand(pos, meta, command)
	if type(command) ~= "table" then return end

	local bufnum
	if command.command ~= "copy" then
		bufnum = validate_buffer_address(command.buffer)
		if not bufnum then return end
	end

	local buffer
	if command.command ~= "createbuffer" and command.command ~= "copy" then
		buffer = read_buffer(meta, bufnum)
		if not buffer then return end
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
		if type(command.channel) ~= "string" then return end

		digilines.receptor_send(pos, digilines.rules.default, command.channel, buffer)
	elseif command.command == "sendregion" then
		if type(command.channel) ~= "string" then return end

		x1, y1, x2, y2 = validate_area(buffer, command.x1, command.y1, command.x2, command.y2)

		if not x1 then return end

		local tempbuf, dstx, dsty = {}
		for y = y1, y2 do
			dsty = y - y1 + 1
			tempbuf[dsty] = {}
			for x = x1, x2 do
				dstx = x - x1 + 1
				tempbuf[dsty][dstx] = buffer[y][x]
			end
		end
		digilines.receptor_send(pos, digilines.rules.default, command.channel, tempbuf)
	elseif command.command == "drawrect" then
		x1, y1, x2, y2 = validate_area(buffer, command.x1, command.y1, command.x2, command.y2)

		if not x1 then return end

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
		x1, y1, x2, y2 = validate_area(buffer, command.x1, command.y1, command.x2, command.y2, true)

		if not x1 then return end

		color = validate_color(command.color)

		-- Handle horizontal and vertical lines
		if x1 == x2 and y1 == y2 then
			buffer[y1][x1] = color
			write_buffer(meta, bufnum, buffer)
			return
		elseif x1 == x2 then
			for y = y1, y2 do
				buffer[y][x1] = color
			end
			write_buffer(meta, bufnum, buffer)
			return
		elseif y1 == y2 then
			for x = x1, x2 do
				buffer[y1][x] = color
			end
			write_buffer(meta, bufnum, buffer)
			return
		end

		-- Use Bresenham's line algorithm
		local dx = math.abs(x2 - x1)
		local dy = math.abs(y2 - y1)
		local slope_x = x1 < x2 and 1 or -1
		local slope_y = y1 < y2 and 1 or -1
		local err = dx - dy
		local err2

		if command.antialias then
			local function plot(x, y, alpha)
				local srcr, srcg, srcb = unpack_color(buffer[y][x])
				local dstr, dstg, dstb = unpack_color(color)

				local r = math.floor(srcr + (dstr - srcr) * (1 - alpha))
				local g = math.floor(srcg + (dstg - srcg) * (1 - alpha))
				local b = math.floor(srcb + (dstb - srcb) * (1 - alpha))

				buffer[y][x] = string.format("%02X%02X%02X", r, g, b)
			end

			local x1_copy
			local distance = dx + dy == 0 and 1 or math.sqrt(dx * dx + dy * dy)

			-- Plot pixels according to perpendicular distance
			while true do
				plot(x1, y1, math.abs(err - dx + dy) / distance)
				err2, x1_copy = err, x1
				if 2 * err2 >= -dx then
					if x1 == x2 then break end
					if err2 + dy < distance then plot(x1, y1 + slope_y, (err2 + dy) / distance) end
					err, x1 = err - dy, x1 + slope_x
				end
				if 2 * err2 <= dy then
					if y1 == y2 then break end
					if dx - err2 < distance then plot(x1_copy + slope_x, y1, (dx - err2) / distance) end
					err, y1 = err + dx, y1 + slope_y
				end
			end
		else
			dy = -dy

			while true do
				buffer[y1][x1] = color
				err2 = err * 2
				if err2 >= dy then
					if x1 == x2 then break end
					err = err + dy
					x1 = x1 + slope_x
				end
				if err2 <= dx then
					if y1 == y2 then break end
					err = err + dx
					y1 = y1 + slope_y
				end
			end
		end

		write_buffer(meta, bufnum, buffer)
	elseif command.command == "drawpoint" then
		x1, y1 = validate_area(buffer, command.x, command.y, command.x, command.y)
		if not x1 then return end

		buffer[y1][x1] = validate_color(command.color)
		write_buffer(meta, bufnum, buffer)
	elseif command.command == "copy" then
		if type(command.xsize) ~= "number" or type(command.ysize) ~= "number" then return end

		local src = validate_buffer_address(command.src)
		local dst = validate_buffer_address(command.dst)
		if not (src and dst) then return end

		local sourcebuffer = read_buffer(meta, src)
		local destbuffer = read_buffer(meta, dst)
		if not (sourcebuffer and destbuffer) then return end

		x1, y1 = validate_area(sourcebuffer, command.srcx, command.srcy, command.srcx, command.srcy)

		x2, y2 = validate_area(destbuffer, command.dstx, command.dsty, command.dstx, command.dsty)

		if not (x1 and x2) then return end

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
				destbuffer[y2 + y][x2 + x] = blend(px1, px2, command.mode, transparent)
			end
		end
		write_buffer(meta, dst, destbuffer)
	elseif command.command == "load" then
		x1, y1 = validate_area(buffer, command.x, command.y, command.x, command.y)
		if not x1 or type(command.data) ~= "table" or type(command.data[1]) ~= "table" or #command.data[1] < 1 then
			return
		end

		ysize = math.min(buffer.ysize - y1 + 1, validate_size(#command.data))
		xsize = math.min(buffer.xsize - x1 + 1, validate_size(#command.data[1]))
		for y = 1, ysize do
			if type(command.data[y]) == "table" then
				for x = 1, xsize do
					-- slightly different behaviour from before refactor:
					-- illegal values are now set to '000000' instead of being skipped
					buffer[y1 + y - 1][x1 + x - 1] = validate_color(command.data[y][x])
				end
			end
		end
		write_buffer(meta, bufnum, buffer)
	elseif command.command == "text" then
		x1, y1 = validate_area(buffer, command.x, command.y, command.x, command.y)
		if
			not x1
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
					if char[chary][charx] and y1 + chary - 1 <= buffer.ysize and x2 + charx - 1 <= buffer.xsize then
						px = buffer[y1 + chary - 1][x2 + charx - 1]
						buffer[y1 + chary - 1][x2 + charx - 1] = blend(color, px, command.mode, "")
					end
				end
			end
		end
		write_buffer(meta, bufnum, buffer)
	elseif command.command == "sendpacked" then
		if type(command.channel) ~= "string" then return end
		local packedtable = {}
		for y = 1, buffer.ysize do
			for x = 1, buffer.xsize do
				table.insert(packedtable, packpixel(buffer[y][x]))
			end
		end
		local packeddata = table.concat(packedtable, "")
		digilines.receptor_send(pos, digilines.rules.default, command.channel, packeddata)
	elseif command.command == "loadpacked" then
		x1, y1 = validate_area(buffer, command.x, command.y, command.x, command.y)
		if not x1 or type(command.data) ~= "string" then return end

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
	elseif command.command == "fakeshader" then
		if type(command.code) ~= "string" then return false, "No code provided" end
		if #command.code > MAX_SHADER_CODE_LENGTH then return false, "Code too large" end

		-- This is technically not needed, but if someone turned off mod security (don't do that!) then someone could abuse bytecode
		-- (mod security disallows bytecode)
		if command.code:byte(1) == 27 then return false, "No bytecode" end

		if command.code:find('"', 1, true) or command.code:find("%[=*%[") then
			return false, "Cannot create strings in shader code"
		end

		local ok, f, errmsg

		-- set up the sandbox
		f, errmsg = loadstring(command.code)
		if not f or errmsg then return false, errmsg end

		if core.global_exists("jit") then jit.off(f, true) end -- debug count hooks don't work with JIT, so turn it off for that function
		-- alternatively we would have to ban loops or parse the code, or involve a lua parser into this, i dont feel like doing that.

		-- The sandbox must not get access to ANY STRINGS
		local env = {
			math = {
				abs = math.abs,
				acos = math.acos,
				asin = math.asin,
				atan = math.atan,
				atan2 = math.atan2,
				ceil = math.ceil,
				cos = math.cos,
				cosh = math.cosh,
				deg = math.deg,
				exp = math.exp,
				floor = math.floor,
				fmod = math.fmod,
				frexp = math.frexp,
				huge = math.huge,
				ldexp = math.ldexp,
				log = math.log,
				log10 = math.log10,
				max = math.max,
				min = math.min,
				modf = math.modf,
				pi = math.pi,
				pow = math.pow,
				rad = math.rad,
				random = math.random,
				-- randomseed = math.randomseed,
				sin = math.sin,
				sinh = math.sinh,
				sqrt = math.sqrt,
				tan = math.tan,
				tanh = math.tanh,
			},
			get_color = function(x, y)
				return unpack_color(buffer[y][x])
			end,

			xsize = buffer.xsize,
			ysize = buffer.ysize,

			-- Variables that change for each pixel:
			r = 0,
			g = 0,
			b = 0,

			x = 0,
			y = 0,
		}
		setfenv(f, env)

		local new_buffer = { xsize = buffer.xsize, ysize = buffer.ysize }
		for y = 1, buffer.ysize do
			new_buffer[y] = {}
		end

		ok, errmsg = pcall(run_shader, env, buffer, new_buffer, f) -- nested pcall because that is how mesecons does it and i already had a nightmare bug where the debug hook somehow escaped containment and started error'ing in random functions
		if not ok then
			return ok, errmsg
		else
			write_buffer(meta, bufnum, new_buffer)
		end
	elseif command.command == "convolutionmatrix" then
		local convolution_matrix = command.matrix
		if not validate_matrix(convolution_matrix, { [3] = true, [5] = true }) then return end
		local matrix_size = #convolution_matrix

		local half_matrix_size = math.floor(matrix_size / 2)

		local new_buffer = { xsize = buffer.xsize, ysize = buffer.ysize }
		xsize, ysize = buffer.xsize, buffer.ysize

		local number_buffer = {} -- a cache to avoid computing unpack_color, yes it would be wiser to just not use strings but blame the first developer that worked on the digistuff GPU, also yes this SIGNIFICANTLY speeds up calculations at least on luajit
		for y = 1, ysize do
			number_buffer[y] = {}
		end
		for y = 1, ysize do
			new_buffer[y] = {}
			for x = 1, xsize do
				local r, g, b = 0, 0, 0
				for y_offset = -half_matrix_size, half_matrix_size do
					for x_offset = -half_matrix_size, half_matrix_size do
						local px, py = x + x_offset, y + y_offset
						if py > 0 and py <= ysize and px > 0 and px <= xsize then
							local pxr, pxg, pxb = unpack_color_with_cache(number_buffer, buffer, px, py)
							local mul_by =
								convolution_matrix[half_matrix_size + 1 + x_offset][half_matrix_size + 1 + y_offset]
							r, g, b = r + pxr * mul_by, g + pxg * mul_by, b + pxb * mul_by
						end
					end
				end
				r = math.min(255, math.max(0, math.floor(r)))
				g = math.min(255, math.max(0, math.floor(g)))
				b = math.min(255, math.max(0, math.floor(b)))
				new_buffer[y][x] = string.format("%02X%02X%02X", r, g, b)
			end
		end

		write_buffer(meta, bufnum, new_buffer)
	elseif command.command == "transform" then
		local matrix = command.matrix -- 2x2 if linear, 3x3 if affine
		if not validate_matrix(matrix, { [2] = true, [3] = true }) then return end

		x1, y1, x2, y2 = validate_area(buffer, command.x1, command.y1, command.x2, command.y2, false)
		if not x1 then return end
		local transparent = validate_color(command.transparent, "#000000")
		local interpolation = command.interpolation
		local interpolate = bilinear_interpolation
		if interpolation == false then interpolate = nearest_neighbor end

		local transform = #matrix == 2 and linear_transform or affine_transform
		if #matrix == 2 then
			matrix = invert_2x2_matrix(matrix)
		elseif #matrix == 3 then
			matrix = invert_3x3_matrix(matrix)
		end

		-- center_x/center_y can be any number, even completely outside of the buffer
		local center_x, center_y = command.center_x or 0, command.center_y or 0
		if type(center_y) ~= "number" then return end
		if type(center_x) ~= "number" then return end

		local changed_buffer = {} -- not a buffer as it doesnt have xsize, ysize
		local cache = {}

		for y = y1, y2 do
			changed_buffer[y] = {}
			cache[y] = {}
		end

		for y = y1, y2 do
			for x = x1, x2 do
				local new_x, new_y = transform(x - center_x, y - center_y, matrix)
				new_x, new_y = new_x + center_x, new_y + center_y
				if new_x == new_x and new_y == new_y then -- checking against NaN
					color = interpolate(buffer, cache, new_x, new_y)
					if color and color ~= transparent then changed_buffer[y][x] = color end
				end
			end
		end

		for y = y1, y2 do
			for x = x1, x2 do
				buffer[y][x] = transparent
			end
		end

		--- layer
		for y = 1, buffer.ysize do
			for x = 1, buffer.xsize do
				buffer[y][x] = changed_buffer[y][x] or buffer[y][x]
			end
		end

		write_buffer(meta, bufnum, buffer)
	end
end

minetest.register_node("digistuff:gpu", {
	description = "Digilines 2D Graphics Processor",
	groups = { cracky = 3, not_blocking_trains = 1 },
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
		"jeija_microcontroller_sides.png",
	},
	inventory_image = "digistuff_gpu_top.png",
	drawtype = "nodebox",
	selection_box = {
		--From luacontroller
		type = "fixed",
		fixed = { -8 / 16, -8 / 16, -8 / 16, 8 / 16, -5 / 16, 8 / 16 },
	},
	_digistuff_channelcopier_fieldname = "channel",
	node_box = {
		--From Luacontroller
		type = "fixed",
		fixed = {
			{ -8 / 16, -8 / 16, -8 / 16, 8 / 16, -7 / 16, 8 / 16 }, -- Bottom slab
			{ -5 / 16, -7 / 16, -5 / 16, 5 / 16, -6 / 16, 5 / 16 }, -- Circuit board
			{ -3 / 16, -6 / 16, -3 / 16, 3 / 16, -5 / 16, 3 / 16 }, -- IC
		},
	},
	paramtype = "light",
	sunlight_propagates = true,
	on_receive_fields = function(pos, formname, fields, sender)
		-- Below link to lua_api.md says: not to check formname
		-- https://github.com/minetest/minetest/blob/2efd0996e61fe82a4922224fa8c039116281d345/doc/lua_api.md?plain=1#L9674
		if not fields.channel then return end

		local name = sender:get_player_name()
		if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, { protection_bypass = true }) then
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
				if meta:get_string("channel") ~= channel or type(msg) ~= "table" then return end

				if type(msg[1]) == "table" then
					for i = 1, MAX_COMMANDS do
						if type(msg[i]) == "table" then
							local ok, errmsg = runcommand(pos, meta, msg[i])

							if ok == false then
								digilines.receptor_send(pos, digilines.rules.default, channel, errmsg)
							end
						end
					end
				else
					runcommand(pos, meta, msg)
				end
			end,
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
			"digilines:wire_std_00000000",
		},
		{ "dye:red", "dye:green", "dye:blue" },
	},
})

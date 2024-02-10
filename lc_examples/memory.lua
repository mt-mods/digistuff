--Digilines Memory Example

--Connect an EEPROM or SRAM chip on channel "memory"
--Enter "help" in the terminal for a command list

local function runcmd(command)
	if command ~= "" then
		print(" "..command,true)
		print()
	end
	if string.sub(command,1,4) == "read" then
		local address = string.sub(command,6,7)
		if string.sub(address,2,2) == " " then address = string.sub(address,1,1) end
		address = tonumber(address)
		if (not address) or address > 31 or address < 0 or math.floor(address) ~= address then
			print("Invalid address - address must be an integer from 0 to 31")
		else
			digiline_send(mem.channel,{command = "read",address = address})
			mem.readsuccess = false
			interrupt(1,"readtimeout")
			return --Suppress printing a new prompt
		end
	elseif string.sub(command,1,5) == "write" then
		local address = string.sub(command,7,8)
		local data = string.sub(command,10,-1)
		if string.sub(address,2,2) == " " then
			address = string.sub(command,7,7)
			data = string.sub(command,9,-1)
		end
		address = tonumber(address)
		if (not address) or address > 31 or address <0 or math.floor(address) ~= address then
			print("Invalid address - address must be an integer from 0 to 31")
		elseif data == "" then
			print("No data specified")
		else
			print(string.format("Wrote to address %d",address))
			digiline_send(mem.channel,{command = "write",address = address,data = data})
		end
	elseif string.sub(command,1,7) == "channel" then
		local channel = string.sub(command,9,-1)
		if channel and channel ~= "" then
			mem.channel = channel
			print("Channel changed")
		else
			print("No channel specified")
		end
	elseif command == "clear" then
		clearterm()
		print(">")
		return --Suppress printing a new prompt - it was done already to omit the blank line
	elseif command == "help" then
		print("Available commands:")
		print("channel <channel>: Changes the digilines channel the memory device is attached to, default is \"memory\"")
		print("clear: Clears the screen")
		print("read <address>: Reads from the specified address and displays the received data")
		print("write <address> <data>: Writes the specified data to the specified address")
		print("help: Shows this help message")
	elseif command == "" then
		--Do nothing
	else
		print("Unknown command - use \"help\" to see a list of valid commands.")
	end
	print()
	print(">")
end

if event.type == "program" then
	mem.channel = "memory"
	runcmd("clear")
elseif event.iid == "readtimeout" and not mem.readsuccess then
	print("No response received. Is there a memory device connected on the channel \""..mem.channel.."\"?")
	print()
	print(">")
elseif event.channel == mem.channel then
	mem.readsuccess = true
	print(event.msg)
	print()
	print(">")
elseif event.type == "terminal" then
	runcmd(event.text)
end

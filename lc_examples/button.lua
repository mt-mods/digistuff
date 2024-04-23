--Digilines Button Example

--Connect a button on the channel "button" with any message.
--When the button is pressed, pin A will toggle.
--If manual light control is selected on the button, the button light will also be flashing.
--If the button has a message set, it will be sent to an LCD on channel "lcd"

if event.type == "program" then
	mem.flash = false
	interrupt(0,"flash")
elseif event.iid == "flash" then
	mem.flash = not mem.flash
	digiline_send("button","light_"..(mem.flash and "on" or "off"))
	interrupt(1,"flash",true)
elseif event.channel == "button" then
	port.a = not port.a
	digiline_send("lcd",event.msg)
end

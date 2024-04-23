--Digilines Dimmable Light Demo

--Connect one or more lights on the channel "light"
--Send pulses on:
----Pin A to make the light brighter
----Pin B to make the light dimmer
----Pin C to set the light to full brightness
----Pin D to turn the light off

if event.type == "program" then
	mem.light = 0
elseif event.type == "on" then
	if event.pin.name == "A" then
		mem.light = math.min(14,mem.light+1)
	elseif event.pin.name == "B" then
		mem.light = math.max(0,mem.light-1)
	elseif event.pin.name == "C" then
		mem.light = 14
	elseif event.pin.name == "D" then
		mem.light = 0
	end
end

digiline_send("light",mem.light)

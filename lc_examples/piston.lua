--Digilines Piston Example

--Connect the piston on the channel "piston"
--Pulse pin A to extend the piston
--Pulse pin B to retract the piston
--Pulse pin C to retract the piston, pulling one node back
--Pulse pin D to silently retract the piston, pulling up to 5 nodes back

if event.type == "on" then
	if event.pin.name == "A" then
		digiline_send("piston","extend")
	elseif event.pin.name == "B" then
		digiline_send("piston","retract")
	elseif event.pin.name == "C" then
		digiline_send("piston","retract_sticky")
	elseif event.pin.name == "D" then
		digiline_send("piston",{action = "retract",allsticky = true,max = 5,sound = "none"})
	end
end

--Digilines I/O Expander Example

--Connect two I/O expanders, one on channel "expander1" and one on "expander2"
--The pins on the second expander will follow the input states on the first one.
--In addition, whenever an input on the first expander changes, a line will be logged to the terminal with the new state.

local function iostr(pin)
	return (pin and "1" or "0")
end

if event.channel == "expander1" then
	digiline_send("expander2",event.msg)
	print(string.format("A: %s B: %s C: %s D: %s",iostr(event.msg.a),iostr(event.msg.b),iostr(event.msg.c),iostr(event.msg.d)))
end

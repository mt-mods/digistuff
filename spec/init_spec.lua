require("mineunit")

mineunit("core")

fixture("digilines")

describe("Digistuff mod initialization", function()

	it("will not fail", function()
		sourcefile("init")
	end)

end)

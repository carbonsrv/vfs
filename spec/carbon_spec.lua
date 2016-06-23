-- Custom type check, doesn't work. :V
--[[
local say = require("say")
-- Type checker
local function is_type(obj, t)
	return type(obj) == t
end
say:set("assertion.type.positive", "Expected %s to be type %s")
say:set("assertion.type.negative", "Expected %s to not be type %s")
assert:register("assertion", "type", is_type, "assertion.is_type.postitive", "assertion.is_type.negative")
--]]

-- Actual tests
describe("carbonvfs", function()
	local vfs = dofile("init.lua")
	describe("should run under carbon and it", function()
		if carbon then
			it("should load carbon specific backends", function()
				assert.equals(type(vfs.backends.physfs), "function")
				assert.equals(type(vfs.backends.gofs), "function")
				assert.equals(type(vfs.backends.shared), "function")
			end)
		else
			it("should work flawlessly", function()
				pending("But the tests aren't running under carbon...")
			end)
		end
	end)
end)


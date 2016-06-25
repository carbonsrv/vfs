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
				assert.equals(type(vfs.backends.sql), "function")
				assert.equals(type(vfs.backends.shared), "function")
			end)
			it("should be able to use the sql backend", function()
				local db = assert(sql.open("ql-mem", "mem"))
				vfs.new("sqltest", "sql", db, {
					tablename = "files",
				})

				local teststr = "Hello World!"
				
				assert(vfs.write("sqltest:/test.txt", teststr))
				local str = assert(vfs.read("sqltest:/test.txt"))
				assert.equals(str, teststr)

				local size = assert(vfs.size("sqltest:/test.txt"))
				assert.equals(size, #teststr)

				local list = assert(vfs.list("sqltest:/"))
				assert.equals(list[1], "test.txt")

				db:close()
			end)
		else
			it("should work flawlessly", function()
				pending("But the tests aren't running under carbon...")
			end)
		end
	end)
end)

